import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';

import 'anthropometric_calculator.dart';
import 'firestore_service.dart';

/// Generates filled Lumasdang records Excel from template using barangay
/// patients and their latest assessment. Cell mapping:
/// - Header: Date(B1), Barangay(D1), Municipality/City(H1), Region(L1)
/// - Data starts row 4: A=Child Sequence, B=Address, C=Mother/Caregiver,
///   D=Full Name of Child, E=IP (Y/N), F=Sex, G=DOB, H=Date Measured,
///   I=Weight(kg), J=Height(cm), K=Age in Months, L=WFA Status,
///   M=HFA Status, N=Weight for Length Status.
class LumasdangRecordsService {
  static const String _templateAsset = 'assets/Lumasdang_records_template.xlsx';

  /// Date format used for Date of Birth and Date Measured in the Excel.
  static String _formatDate(DateTime? d) {
    if (d == null) return '';
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseDate(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final trimmed = s.trim();
    // Try ISO first
    final dt = DateTime.tryParse(trimmed);
    if (dt != null) return dt;
    // MM-DD-YYYY or MM/DD/YYYY
    final parts = trimmed.split(RegExp(r'[-/]'));
    if (parts.length >= 3) {
      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (month != null && day != null && year != null) {
        return DateTime(year, month, day);
      }
      if (parts[0].length == 4) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) return DateTime(y, m, d);
      }
    }
    return null;
  }

  /// Age in months between two dates.
  static int? _ageInMonths(DateTime? dob, DateTime? measurementDate) {
    if (dob == null || measurementDate == null) return null;
    if (measurementDate.isBefore(dob)) return null;
    final years = measurementDate.year - dob.year;
    final months = measurementDate.month - dob.month;
    final days = measurementDate.day - dob.day;
    int totalMonths = years * 12 + months;
    if (days < 0) totalMonths -= 1;
    return totalMonths.clamp(0, 999);
  }

  /// Unique key for deduplication: same child = same name + DOB.
  static String _patientKey(Map<String, dynamic> doc) {
    final d = (doc['demographic'] ?? {}) as Map<String, dynamic>;
    final last = (d['lastName'] ?? '').toString().trim().toLowerCase();
    final first = (d['firstName'] ?? '').toString().trim().toLowerCase();
    final dob = (d['dateOfBirth'] ?? '').toString().trim();
    return '$last|$first|$dob';
  }

  /// Get the date of the latest assessment for ordering.
  static DateTime? _assessmentDate(Map<String, dynamic>? assessment) {
    if (assessment == null) return null;
    final anthro = (assessment['anthropometric'] ?? {}) as Map<String, dynamic>;
    final dateStr = anthro['dateOfMeasurement']?.toString();
    if (dateStr != null && dateStr.trim().isNotEmpty) {
      final d = _parseDate(dateStr);
      if (d != null) return d;
    }
    try {
      final createdAt = assessment['createdAt'];
      if (createdAt != null) return (createdAt as dynamic).toDate();
    } catch (_) {}
    return null;
  }

  /// Merge anthropometric from assessment (preferred) with patient doc (initial form data). Assessment wins when present.
  static Map<String, dynamic> _mergeAnthropometric(
    Map<String, dynamic> fromAssessment,
    Map<String, dynamic> fromPatient,
  ) {
    final merged = Map<String, dynamic>.from(fromPatient);
    for (final e in fromAssessment.entries) {
      final v = e.value;
      if (v != null && v.toString().trim().isNotEmpty) {
        merged[e.key] = v;
      }
    }
    return merged;
  }

  /// Generate filled Excel file and return its path.
  /// Deduplicates by child identity (lastName + firstName + dateOfBirth) and
  /// uses the patient record with the most recent assessment for each unique child.
  static Future<String> generateExcelFile() async {
    final result = await _buildExcelFileBytesAndName();
    final dir = await getTemporaryDirectory();
    final outPath = p.join(dir.path, result.fileName);
    await File(outPath).writeAsBytes(result.bytes);
    return outPath;
  }

  /// Generate filled Excel file and return bytes + filename (for web download).
  static Future<({Uint8List bytes, String fileName})> generateExcelBytes() {
    return _buildExcelFileBytesAndName();
  }

  /// Core implementation used by both file-path and bytes-based generation.
  static Future<({Uint8List bytes, String fileName})> _buildExcelFileBytesAndName() async {
    final data = await rootBundle.load(_templateAsset);
    final bytes = Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );

    final firestore = FirestoreService();
    final barangayName = await firestore.getCurrentUserBarangayName();
    final patients = await firestore.getPatientsFromBarangay();

    // Group by unique child (name + DOB) so we output one row per child
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final p in patients) {
      final doc = p as Map<String, dynamic>;
      final id = doc['id'] as String?;
      if (id == null) continue;
      // Skip archived children so the Excel matches the active Patients list.
      if (doc['isArchived'] == true) continue;
      final k = _patientKey(doc);
      groups.putIfAbsent(k, () => []).add(doc);
    }

    // For each group, pick the patient that has the most recent assessment; use that patient + latest assessment for the row
    final List<({Map<String, dynamic> patient, Map<String, dynamic>? assessment})> uniqueRows = [];
    for (final entry in groups.entries) {
      final list = entry.value;
      Map<String, dynamic>? bestPatient;
      Map<String, dynamic>? bestAssessment;
      DateTime? bestDate;
      for (final p in list) {
        final assessments = await firestore.getAssessmentsForBarangayPatient(p['id'] as String);
        final latest = assessments.isNotEmpty ? assessments.last : null;
        final d = _assessmentDate(latest);
        if (bestDate == null || (d != null && d.isAfter(bestDate))) {
          bestDate = d;
          bestPatient = p;
          bestAssessment = latest;
        } else if (bestPatient == null) {
          bestPatient = p;
          bestAssessment = latest;
        }
      }
      uniqueRows.add((patient: bestPatient ?? list.first, assessment: bestAssessment));
    }

    final updates = <String, dynamic>{};

    // Header: B1=Date, D1=Barangay, H1=Municipality/City, L1=Region
    final today = DateTime.now();
    updates['B1'] = _formatDate(today);
    updates['D1'] = barangayName.trim().isEmpty ? '—' : barangayName.trim();
    // Fixed municipality and region headers as requested
    updates['H1'] = 'La Trinidad';
    updates['L1'] = 'Cordillera Administrative Region';

    const int firstDataRow = 4;
    int row = firstDataRow;
    for (var i = 0; i < uniqueRows.length; i++) {
      final doc = uniqueRows[i].patient;
      final latestAssessment = uniqueRows[i].assessment;
      final demographic = (doc['demographic'] ?? {}) as Map<String, dynamic>;
      // Use assessment anthropometric when present; else fall back to initial form data on patient doc (from home page save)
      final assessmentAnthro = latestAssessment != null
          ? (latestAssessment['anthropometric'] ?? {}) as Map<String, dynamic>
          : <String, dynamic>{};
      final patientAnthro = (doc['anthropometric'] ?? {}) as Map<String, dynamic>;
      final anthropometric = _mergeAnthropometric(assessmentAnthro, patientAnthro);

      final lastName = (demographic['lastName'] ?? '').toString().trim();
      final firstName = (demographic['firstName'] ?? '').toString().trim();
      final childName = lastName.isEmpty && firstName.isEmpty
          ? ''
          : '$lastName, $firstName'.replaceFirst(RegExp(r'^,\s*'), '').replaceFirst(RegExp(r',\s*$'), '');
      final address = (demographic['address'] ?? '').toString().trim();
      final mother = (demographic['mother'] ?? '').toString().trim();
      final sexRaw = (demographic['sex'] ?? '').toString().trim();
      final sex = sexRaw.isEmpty ? '' : (sexRaw.toLowerCase().startsWith('m') || sexRaw.toLowerCase() == 'lalaki' ? 'M' : 'F');
      final dobStr = (demographic['dateOfBirth'] ?? '').toString().trim();
      final dob = _parseDate(dobStr);

      // Date measured: from merged anthropometric (assessment or initial form on patient), then assessment createdAt
      String dateMeasuredStr = '';
      DateTime? measurementDate;
      final dateOfMeas = anthropometric['dateOfMeasurement']?.toString();
      if (dateOfMeas != null && dateOfMeas.trim().isNotEmpty) {
        dateMeasuredStr = dateOfMeas.trim();
        measurementDate = _parseDate(dateMeasuredStr);
      }
      if (measurementDate == null && latestAssessment != null) {
        final createdAt = latestAssessment['createdAt'];
        if (createdAt != null) {
          try {
            measurementDate = (createdAt as dynamic).toDate();
            dateMeasuredStr = _formatDate(measurementDate);
          } catch (_) {}
        }
      }

      final weightStr = (anthropometric['weight'] ?? '').toString().trim();
      final heightStr = (anthropometric['height'] ?? '').toString().trim();
      final num? weightKg = double.tryParse(weightStr.replaceAll(',', '.'));
      final num? heightCm = double.tryParse(heightStr.replaceAll(',', '.'));

      String wfaStatus = (anthropometric['weightForAge'] ?? '').toString().trim();
      String hfaStatus = (anthropometric['heightForAge'] ?? '').toString().trim();
      String wflStatus = (anthropometric['weightForHeight'] ?? '').toString().trim();

      // If Weight for Length/Height (Lt/Ht) is empty but we have weight, height, DOB, sex and date measured, compute it
      if (wflStatus.isEmpty &&
          weightStr.isNotEmpty &&
          heightStr.isNotEmpty &&
          dobStr.isNotEmpty &&
          dateMeasuredStr.isNotEmpty &&
          sexRaw.isNotEmpty) {
        final result = AnthropometricCalculator.calculate(
          weightStr: weightStr,
          heightStr: heightStr,
          ageStr: '',
          sexStr: sexRaw,
          dobStr: dobStr,
          measurementDateStr: dateMeasuredStr,
        );
        if (result?.weightForHeight != null && result!.weightForHeight!.trim().isNotEmpty) {
          wflStatus = result.weightForHeight!.trim();
        } else {
          // Track why export still has empty Weight for Lt/Ht (calculator returned null or no WFL/WH)
          print(
            '[Lumasdang export] Weight for Lt/Ht empty for "$childName": '
            'calculator returned null or out of WHO range (0–2y length 45–110 cm, 2–5y height 65–120 cm). '
            'weight=$weightStr, height=$heightStr, DOB=$dobStr, dateMeasured=$dateMeasuredStr, sex=$sexRaw',
          );
        }
      }

      final ageMonths = _ageInMonths(dob, measurementDate);

      // IP group: from assessment (demographic.belongsToIpGroup or top-level) or patient demographic
      final ipFromAssessment = latestAssessment != null
          ? (latestAssessment['demographic'] is Map
              ? (latestAssessment['demographic'] as Map<String, dynamic>)['belongsToIpGroup']
              : latestAssessment['belongsToIpGroup'])
          : null;
      final ipFromPatient = (demographic['belongsToIpGroup']);
      final ipValue = ipFromAssessment ?? ipFromPatient;

      // IP ethnicity: prefer value from latest assessment.demographic, then patient.demographic
      String ipEthnicity = '';
      if (latestAssessment != null) {
        final assessDemo = latestAssessment['demographic'];
        if (assessDemo is Map<String, dynamic>) {
          ipEthnicity = (assessDemo['ipEthnicity'] ?? '').toString().trim();
        }
      }
      if (ipEthnicity.isEmpty) {
        ipEthnicity = (demographic['ipEthnicity'] ?? '').toString().trim();
      }

      final String ipGroupStr;
      if (ipValue == true) {
        // When child belongs to IP group, append ethnicity inside the same column if available
        ipGroupStr = ipEthnicity.isNotEmpty ? 'YES - $ipEthnicity' : 'YES';
      } else if (ipValue == false) {
        ipGroupStr = 'NO';
      } else if (ipValue is String) {
        final v = (ipValue as String).trim().toUpperCase();
        final base = (v == 'YES' || v == 'Y')
            ? 'YES'
            : (v == 'NO' || v == 'N')
                ? 'NO'
                : (ipValue as String).trim();
        ipGroupStr = base == 'YES' && ipEthnicity.isNotEmpty ? '$base - $ipEthnicity' : base;
      } else {
        ipGroupStr = '';
      }

      updates['A$row'] = i + 1;
      updates['B$row'] = address;
      updates['C$row'] = mother;
      updates['D$row'] = childName;
      updates['E$row'] = ipGroupStr; // Belongs to IP group? (YES/NO) – from row 4
      updates['F$row'] = sex;
      updates['G$row'] = dobStr.isEmpty ? _formatDate(dob) : dobStr;
      updates['H$row'] = dateMeasuredStr;
      if (weightKg != null) {
        updates['I$row'] = weightKg;
      } else {
        updates['I$row'] = weightStr;
      }
      if (heightCm != null) {
        updates['J$row'] = heightCm;
      } else {
        updates['J$row'] = heightStr;
      }
      if (ageMonths != null) {
        updates['K$row'] = ageMonths;
      } else {
        updates['K$row'] = '';
      }
      updates['L$row'] = wfaStatus;
      updates['M$row'] = hfaStatus;
      updates['N$row'] = wflStatus;

      row++;
    }

    final patched = _patchXlsxCellValues(bytes, updates);
    final safeName = _sanitizeFileName(barangayName.trim());
    final fileName = safeName.isEmpty
        ? 'lumasdang_records_${DateTime.now().millisecondsSinceEpoch}.xlsx'
        : 'lumasdang_records_$safeName.xlsx';
    return (bytes: patched, fileName: fileName);
  }

  /// Sanitize barangay name for use in filename: spaces -> underscore, remove invalid chars.
  static String _sanitizeFileName(String name) {
    if (name.isEmpty) return '';
    final noSpaces = name.replaceAll(RegExp(r'\s+'), '_');
    return noSpaces.replaceAll(RegExp(r'[^\w\-]'), '');
  }

  /// Patches the template xlsx by updating only cell values. Supports int, num, and String.
  static Uint8List _patchXlsxCellValues(Uint8List templateBytes, Map<String, dynamic> updates) {
    if (updates.isEmpty) return templateBytes;

    final archive = ZipDecoder().decodeBytes(templateBytes);
    String? sheetPath;
    for (final file in archive.files) {
      if (file.name.startsWith('xl/worksheets/sheet') && file.name.endsWith('.xml')) {
        sheetPath = file.name;
        break;
      }
    }
    if (sheetPath == null) throw Exception('Lumasdang records template: no worksheet found.');

    final stringUpdates = <String, int>{};
    final newStrings = <String>[];
    for (final e in updates.entries) {
      if (e.value is String) {
        final s = e.value as String;
        if (!stringUpdates.containsKey(s)) {
          stringUpdates[s] = newStrings.length;
          newStrings.add(s);
        }
      }
    }

    int sharedStringIndexOffset = 0;
    if (newStrings.isNotEmpty) {
      final sharedStringsFile = archive.findFile('xl/sharedStrings.xml');
      if (sharedStringsFile != null) {
        final sstDoc = XmlDocument.parse(String.fromCharCodes(sharedStringsFile.content));
        final sst = sstDoc.rootElement;
        sharedStringIndexOffset = sst.findElements('si').length;
        for (final s in newStrings) {
          final escaped = s
              .replaceAll('&', '&amp;')
              .replaceAll('<', '&lt;')
              .replaceAll('>', '&gt;')
              .replaceAll('"', '&quot;')
              .replaceAll("'", '&apos;');
          final si = XmlElement(XmlName('si'), [], [XmlElement(XmlName('t'), [], [XmlText(escaped)])]);
          sst.children.add(si);
        }
        final count = sst.getAttribute('count');
        final newCount = (count != null ? int.tryParse(count) ?? 0 : sharedStringIndexOffset) + newStrings.length;
        sst.setAttribute('count', newCount.toString());
        sst.setAttribute('uniqueCount', newCount.toString());
        final newSstBytes = Uint8List.fromList(sstDoc.toXmlString(pretty: false, indent: '  ').codeUnits);
        archive.removeFile(sharedStringsFile);
        archive.addFile(ArchiveFile('xl/sharedStrings.xml', newSstBytes.length, newSstBytes));
      } else {
        final sb = StringBuffer();
        sb.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="${newStrings.length}" uniqueCount="${newStrings.length}">');
        for (final s in newStrings) {
          final escaped = s
              .replaceAll('&', '&amp;')
              .replaceAll('<', '&lt;')
              .replaceAll('>', '&gt;')
              .replaceAll('"', '&quot;')
              .replaceAll("'", '&apos;');
          sb.write('<si><t>$escaped</t></si>');
        }
        sb.write('</sst>');
        final newSstBytes = Uint8List.fromList(sb.toString().codeUnits);
        archive.addFile(ArchiveFile('xl/sharedStrings.xml', newSstBytes.length, newSstBytes));
      }
    }

    final refToSharedIndex = <String, int>{};
    for (final e in updates.entries) {
      if (e.value is String) {
        final idx = stringUpdates[e.value as String]!;
        refToSharedIndex[e.key] = sharedStringIndexOffset + idx;
      }
    }

    final sheetFile = archive.findFile(sheetPath);
    if (sheetFile == null) throw Exception('Lumasdang records template: worksheet file not found.');
    final sheetDoc = XmlDocument.parse(String.fromCharCodes(sheetFile.content));

    for (final c in sheetDoc.findAllElements('c')) {
      final r = c.getAttribute('r');
      if (r == null || !updates.containsKey(r)) continue;
      final value = updates[r]!;
      final vEls = c.findElements('v').toList();
      final vNode = vEls.isNotEmpty ? vEls.first : null;

      if (value is int || value is num) {
        c.attributes.removeWhere((a) => a.name.local == 't');
        final str = value.toString();
        if (vNode != null) {
          vNode.children.clear();
          vNode.children.add(XmlText(str));
        } else {
          c.children.add(XmlElement(XmlName('v'), [], [XmlText(str)]));
        }
      } else if (value is String) {
        final idx = refToSharedIndex[r]!;
        c.attributes.removeWhere((a) => a.name.local == 't');
        c.setAttribute('t', 's');
        if (vNode != null) {
          vNode.children.clear();
          vNode.children.add(XmlText(idx.toString()));
        } else {
          c.children.add(XmlElement(XmlName('v'), [], [XmlText(idx.toString())]));
        }
      }
    }

    final newSheetBytes = Uint8List.fromList(sheetDoc.toXmlString(pretty: false, indent: '  ').codeUnits);
    archive.removeFile(sheetFile);
    archive.addFile(ArchiveFile(sheetPath, newSheetBytes.length, newSheetBytes));

    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }
}
