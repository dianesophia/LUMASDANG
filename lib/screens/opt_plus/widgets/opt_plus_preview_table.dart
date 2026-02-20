import 'package:flutter/material.dart';

import '../../../services/opt_plus_service.dart';

/// Data passed to the preview table.
class OptPlusPreviewData {
  final String barangayName;
  final OptPlusSummary summary;
  final OptPlusIndicatorSummary indicatorSummary;
  final OptPlusBoys0to5Counts boys0to5;
  final OptPlusBoys0to5Counts girls0to5;
  final OptPlusBoys0to5Counts boys6to11;
  final OptPlusBoys0to5Counts girls6to11;
  final OptPlusBoys0to5Counts boys12to23;
  final OptPlusBoys0to5Counts girls12to23;
  final OptPlusBoys0to5Counts boys24to35;
  final OptPlusBoys0to5Counts girls24to35;
  final OptPlusBoys0to5Counts boys36to47;
  final OptPlusBoys0to5Counts girls36to47;
  final OptPlusBoys0to5Counts boys48to59;
  final OptPlusBoys0to5Counts girls48to59;

  const OptPlusPreviewData({
    required this.barangayName,
    required this.summary,
    required this.indicatorSummary,
    required this.boys0to5,
    required this.girls0to5,
    required this.boys6to11,
    required this.girls6to11,
    required this.boys12to23,
    required this.girls12to23,
    required this.boys24to35,
    required this.girls24to35,
    required this.boys36to47,
    required this.girls36to47,
    required this.boys48to59,
    required this.girls48to59,
  });
}

class OptPlusPreviewTable extends StatelessWidget {
  final OptPlusPreviewData data;

  const OptPlusPreviewTable({super.key, required this.data});

  static TableRow _buildRow(String label, int boysVal, int girlsVal, int totalVal, [int? total0to59, int? total0to23]) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(6), child: Text(label, style: const TextStyle(fontSize: 11))),
        Padding(padding: const EdgeInsets.all(6), child: Text('$boysVal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
        Padding(padding: const EdgeInsets.all(6), child: Text('$girlsVal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
        Padding(padding: const EdgeInsets.all(6), child: Text('$totalVal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
        Padding(padding: const EdgeInsets.all(6), child: Text(total0to59 != null ? '$total0to59' : '—', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
        Padding(padding: const EdgeInsets.all(6), child: Text(total0to23 != null ? '$total0to23' : '—', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
      ],
    );
  }

  static TableRow _sectionHeader(String label) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade300),
      children: [
        Padding(padding: const EdgeInsets.all(6), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11))),
        const Padding(padding: EdgeInsets.all(6), child: Text('—', style: TextStyle(fontSize: 11))),
        const Padding(padding: EdgeInsets.all(6), child: Text('—', style: TextStyle(fontSize: 11))),
        const Padding(padding: EdgeInsets.all(6), child: Text('—', style: TextStyle(fontSize: 11))),
        const Padding(padding: EdgeInsets.all(6), child: Text('—', style: TextStyle(fontSize: 11))),
        const Padding(padding: EdgeInsets.all(6), child: Text('—', style: TextStyle(fontSize: 11))),
      ],
    );
  }

  /// Row 13 totals (all patients): sum of assessments per indicator type.
  static int _row13TotalMuac(OptPlusPreviewData data) {
    final t = _total0to59ValuesStatic(data);
    return t[12] + t[13] + t[14]; // muacNormal, muacMwMam, muacSwSam
  }
  static int _row13TotalWfa(OptPlusPreviewData data) {
    final t = _total0to59ValuesStatic(data);
    return t[0] + t[1] + t[2]; // wfaNormal, wfaMuw, wfaSuw
  }
  static int _row13TotalHfa(OptPlusPreviewData data) {
    final t = _total0to59ValuesStatic(data);
    return t[3] + t[4] + t[5] + t[6]; // hfaNormal, hfaTall, hfaMst, hfaSst
  }
  static int _row13TotalWfl(OptPlusPreviewData data) {
    final t = _total0to59ValuesStatic(data);
    return t[7] + t[8] + t[9] + t[10] + t[11]; // wflNormal, wflOw, wflOb, wflMwMam, wflSwSam
  }

  static List<int> _total0to59ValuesStatic(OptPlusPreviewData data) {
    final b05 = data.boys0to5, g05 = data.girls0to5;
    final b611 = data.boys6to11, g611 = data.girls6to11;
    final b1223 = data.boys12to23, g1223 = data.girls12to23;
    final b2435 = data.boys24to35, g2435 = data.girls24to35;
    final b3647 = data.boys36to47, g3647 = data.girls36to47;
    final b4859 = data.boys48to59, g4859 = data.girls48to59;
    return [
      b05.wfaNormal + g05.wfaNormal + b611.wfaNormal + g611.wfaNormal + b1223.wfaNormal + g1223.wfaNormal + b2435.wfaNormal + g2435.wfaNormal + b3647.wfaNormal + g3647.wfaNormal + b4859.wfaNormal + g4859.wfaNormal,
      b05.wfaMuw + g05.wfaMuw + b611.wfaMuw + g611.wfaMuw + b1223.wfaMuw + g1223.wfaMuw + b2435.wfaMuw + g2435.wfaMuw + b3647.wfaMuw + g3647.wfaMuw + b4859.wfaMuw + g4859.wfaMuw,
      b05.wfaSuw + g05.wfaSuw + b611.wfaSuw + g611.wfaSuw + b1223.wfaSuw + g1223.wfaSuw + b2435.wfaSuw + g2435.wfaSuw + b3647.wfaSuw + g3647.wfaSuw + b4859.wfaSuw + g4859.wfaSuw,
      b05.hfaNormal + g05.hfaNormal + b611.hfaNormal + g611.hfaNormal + b1223.hfaNormal + g1223.hfaNormal + b2435.hfaNormal + g2435.hfaNormal + b3647.hfaNormal + g3647.hfaNormal + b4859.hfaNormal + g4859.hfaNormal,
      b05.hfaTall + g05.hfaTall + b611.hfaTall + g611.hfaTall + b1223.hfaTall + g1223.hfaTall + b2435.hfaTall + g2435.hfaTall + b3647.hfaTall + g3647.hfaTall + b4859.hfaTall + g4859.hfaTall,
      b05.hfaMst + g05.hfaMst + b611.hfaMst + g611.hfaMst + b1223.hfaMst + g1223.hfaMst + b2435.hfaMst + g2435.hfaMst + b3647.hfaMst + g3647.hfaMst + b4859.hfaMst + g4859.hfaMst,
      b05.hfaSst + g05.hfaSst + b611.hfaSst + g611.hfaSst + b1223.hfaSst + g1223.hfaSst + b2435.hfaSst + g2435.hfaSst + b3647.hfaSst + g3647.hfaSst + b4859.hfaSst + g4859.hfaSst,
      b05.wflNormal + g05.wflNormal + b611.wflNormal + g611.wflNormal + b1223.wflNormal + g1223.wflNormal + b2435.wflNormal + g2435.wflNormal + b3647.wflNormal + g3647.wflNormal + b4859.wflNormal + g4859.wflNormal,
      b05.wflOw + g05.wflOw + b611.wflOw + g611.wflOw + b1223.wflOw + g1223.wflOw + b2435.wflOw + g2435.wflOw + b3647.wflOw + g3647.wflOw + b4859.wflOw + g4859.wflOw,
      b05.wflOb + g05.wflOb + b611.wflOb + g611.wflOb + b1223.wflOb + g1223.wflOb + b2435.wflOb + g2435.wflOb + b3647.wflOb + g3647.wflOb + b4859.wflOb + g4859.wflOb,
      b05.wflMwMam + g05.wflMwMam + b611.wflMwMam + g611.wflMwMam + b1223.wflMwMam + g1223.wflMwMam + b2435.wflMwMam + g2435.wflMwMam + b3647.wflMwMam + g3647.wflMwMam + b4859.wflMwMam + g4859.wflMwMam,
      b05.wflSwSam + g05.wflSwSam + b611.wflSwSam + g611.wflSwSam + b1223.wflSwSam + g1223.wflSwSam + b2435.wflSwSam + g2435.wflSwSam + b3647.wflSwSam + g3647.wflSwSam + b4859.wflSwSam + g4859.wflSwSam,
      b05.muacNormal + g05.muacNormal + b611.muacNormal + g611.muacNormal + b1223.muacNormal + g1223.muacNormal + b2435.muacNormal + g2435.muacNormal + b3647.muacNormal + g3647.muacNormal + b4859.muacNormal + g4859.muacNormal,
      b05.muacMwMam + g05.muacMwMam + b611.muacMwMam + g611.muacMwMam + b1223.muacMwMam + g1223.muacMwMam + b2435.muacMwMam + g2435.muacMwMam + b3647.muacMwMam + g3647.muacMwMam + b4859.muacMwMam + g4859.muacMwMam,
      b05.muacSwSam + g05.muacSwSam + b611.muacSwSam + g611.muacSwSam + b1223.muacSwSam + g1223.muacSwSam + b2435.muacSwSam + g2435.muacSwSam + b3647.muacSwSam + g3647.muacSwSam + b4859.muacSwSam + g4859.muacSwSam,
    ];
  }

  /// 0–59 months total (column T): sum of each indicator across all six age bands.
  List<int> _total0to59Values() {
    final b05 = data.boys0to5, g05 = data.girls0to5;
    final b611 = data.boys6to11, g611 = data.girls6to11;
    final b1223 = data.boys12to23, g1223 = data.girls12to23;
    final b2435 = data.boys24to35, g2435 = data.girls24to35;
    final b3647 = data.boys36to47, g3647 = data.girls36to47;
    final b4859 = data.boys48to59, g4859 = data.girls48to59;
    return [
      b05.wfaNormal + g05.wfaNormal + b611.wfaNormal + g611.wfaNormal + b1223.wfaNormal + g1223.wfaNormal + b2435.wfaNormal + g2435.wfaNormal + b3647.wfaNormal + g3647.wfaNormal + b4859.wfaNormal + g4859.wfaNormal,
      b05.wfaMuw + g05.wfaMuw + b611.wfaMuw + g611.wfaMuw + b1223.wfaMuw + g1223.wfaMuw + b2435.wfaMuw + g2435.wfaMuw + b3647.wfaMuw + g3647.wfaMuw + b4859.wfaMuw + g4859.wfaMuw,
      b05.wfaSuw + g05.wfaSuw + b611.wfaSuw + g611.wfaSuw + b1223.wfaSuw + g1223.wfaSuw + b2435.wfaSuw + g2435.wfaSuw + b3647.wfaSuw + g3647.wfaSuw + b4859.wfaSuw + g4859.wfaSuw,
      b05.hfaNormal + g05.hfaNormal + b611.hfaNormal + g611.hfaNormal + b1223.hfaNormal + g1223.hfaNormal + b2435.hfaNormal + g2435.hfaNormal + b3647.hfaNormal + g3647.hfaNormal + b4859.hfaNormal + g4859.hfaNormal,
      b05.hfaTall + g05.hfaTall + b611.hfaTall + g611.hfaTall + b1223.hfaTall + g1223.hfaTall + b2435.hfaTall + g2435.hfaTall + b3647.hfaTall + g3647.hfaTall + b4859.hfaTall + g4859.hfaTall,
      b05.hfaMst + g05.hfaMst + b611.hfaMst + g611.hfaMst + b1223.hfaMst + g1223.hfaMst + b2435.hfaMst + g2435.hfaMst + b3647.hfaMst + g3647.hfaMst + b4859.hfaMst + g4859.hfaMst,
      b05.hfaSst + g05.hfaSst + b611.hfaSst + g611.hfaSst + b1223.hfaSst + g1223.hfaSst + b2435.hfaSst + g2435.hfaSst + b3647.hfaSst + g3647.hfaSst + b4859.hfaSst + g4859.hfaSst,
      b05.wflNormal + g05.wflNormal + b611.wflNormal + g611.wflNormal + b1223.wflNormal + g1223.wflNormal + b2435.wflNormal + g2435.wflNormal + b3647.wflNormal + g3647.wflNormal + b4859.wflNormal + g4859.wflNormal,
      b05.wflOw + g05.wflOw + b611.wflOw + g611.wflOw + b1223.wflOw + g1223.wflOw + b2435.wflOw + g2435.wflOw + b3647.wflOw + g3647.wflOw + b4859.wflOw + g4859.wflOw,
      b05.wflOb + g05.wflOb + b611.wflOb + g611.wflOb + b1223.wflOb + g1223.wflOb + b2435.wflOb + g2435.wflOb + b3647.wflOb + g3647.wflOb + b4859.wflOb + g4859.wflOb,
      b05.wflMwMam + g05.wflMwMam + b611.wflMwMam + g611.wflMwMam + b1223.wflMwMam + g1223.wflMwMam + b2435.wflMwMam + g2435.wflMwMam + b3647.wflMwMam + g3647.wflMwMam + b4859.wflMwMam + g4859.wflMwMam,
      b05.wflSwSam + g05.wflSwSam + b611.wflSwSam + g611.wflSwSam + b1223.wflSwSam + g1223.wflSwSam + b2435.wflSwSam + g2435.wflSwSam + b3647.wflSwSam + g3647.wflSwSam + b4859.wflSwSam + g4859.wflSwSam,
      b05.muacNormal + g05.muacNormal + b611.muacNormal + g611.muacNormal + b1223.muacNormal + g1223.muacNormal + b2435.muacNormal + g2435.muacNormal + b3647.muacNormal + g3647.muacNormal + b4859.muacNormal + g4859.muacNormal,
      b05.muacMwMam + g05.muacMwMam + b611.muacMwMam + g611.muacMwMam + b1223.muacMwMam + g1223.muacMwMam + b2435.muacMwMam + g2435.muacMwMam + b3647.muacMwMam + g3647.muacMwMam + b4859.muacMwMam + g4859.muacMwMam,
      b05.muacSwSam + g05.muacSwSam + b611.muacSwSam + g611.muacSwSam + b1223.muacSwSam + g1223.muacSwSam + b2435.muacSwSam + g2435.muacSwSam + b3647.muacSwSam + g3647.muacSwSam + b4859.muacSwSam + g4859.muacSwSam,
    ];
  }

  /// F1K 0–23 months total (column V): sum of each indicator over 0–5, 6–11, 12–23 only.
  List<int> _total0to23Values() {
    final b05 = data.boys0to5, g05 = data.girls0to5;
    final b611 = data.boys6to11, g611 = data.girls6to11;
    final b1223 = data.boys12to23, g1223 = data.girls12to23;
    return [
      b05.wfaNormal + g05.wfaNormal + b611.wfaNormal + g611.wfaNormal + b1223.wfaNormal + g1223.wfaNormal,
      b05.wfaMuw + g05.wfaMuw + b611.wfaMuw + g611.wfaMuw + b1223.wfaMuw + g1223.wfaMuw,
      b05.wfaSuw + g05.wfaSuw + b611.wfaSuw + g611.wfaSuw + b1223.wfaSuw + g1223.wfaSuw,
      b05.hfaNormal + g05.hfaNormal + b611.hfaNormal + g611.hfaNormal + b1223.hfaNormal + g1223.hfaNormal,
      b05.hfaTall + g05.hfaTall + b611.hfaTall + g611.hfaTall + b1223.hfaTall + g1223.hfaTall,
      b05.hfaMst + g05.hfaMst + b611.hfaMst + g611.hfaMst + b1223.hfaMst + g1223.hfaMst,
      b05.hfaSst + g05.hfaSst + b611.hfaSst + g611.hfaSst + b1223.hfaSst + g1223.hfaSst,
      b05.wflNormal + g05.wflNormal + b611.wflNormal + g611.wflNormal + b1223.wflNormal + g1223.wflNormal,
      b05.wflOw + g05.wflOw + b611.wflOw + g611.wflOw + b1223.wflOw + g1223.wflOw,
      b05.wflOb + g05.wflOb + b611.wflOb + g611.wflOb + b1223.wflOb + g1223.wflOb,
      b05.wflMwMam + g05.wflMwMam + b611.wflMwMam + g611.wflMwMam + b1223.wflMwMam + g1223.wflMwMam,
      b05.wflSwSam + g05.wflSwSam + b611.wflSwSam + g611.wflSwSam + b1223.wflSwSam + g1223.wflSwSam,
      b05.muacNormal + g05.muacNormal + b611.muacNormal + g611.muacNormal + b1223.muacNormal + g1223.muacNormal,
      b05.muacMwMam + g05.muacMwMam + b611.muacMwMam + g611.muacMwMam + b1223.muacMwMam + g1223.muacMwMam,
      b05.muacSwSam + g05.muacSwSam + b611.muacSwSam + g611.muacSwSam + b1223.muacSwSam + g1223.muacSwSam,
    ];
  }

  List<TableRow> _buildAgeBandRows(OptPlusBoys0to5Counts boys, OptPlusBoys0to5Counts girls) {
    return [
      _buildRow('WFA - Normal', boys.wfaNormal, girls.wfaNormal, boys.wfaNormal + girls.wfaNormal),
      _buildRow('WFA - MUW', boys.wfaMuw, girls.wfaMuw, boys.wfaMuw + girls.wfaMuw),
      _buildRow('WFA - SUW', boys.wfaSuw, girls.wfaSuw, boys.wfaSuw + girls.wfaSuw),
      _buildRow('L/HFA - Normal', boys.hfaNormal, girls.hfaNormal, boys.hfaNormal + girls.hfaNormal),
      _buildRow('L/HFA - Tall', boys.hfaTall, girls.hfaTall, boys.hfaTall + girls.hfaTall),
      _buildRow('L/HFA - MSt', boys.hfaMst, girls.hfaMst, boys.hfaMst + girls.hfaMst),
      _buildRow('L/HFA - SSt', boys.hfaSst, girls.hfaSst, boys.hfaSst + girls.hfaSst),
      _buildRow('WFL/H - Normal', boys.wflNormal, girls.wflNormal, boys.wflNormal + girls.wflNormal),
      _buildRow('WFL/H - OW', boys.wflOw, girls.wflOw, boys.wflOw + girls.wflOw),
      _buildRow('WFL/H - Ob', boys.wflOb, girls.wflOb, boys.wflOb + girls.wflOb),
      _buildRow('WFL/H - MW/MAM', boys.wflMwMam, girls.wflMwMam, boys.wflMwMam + girls.wflMwMam),
      _buildRow('WFL/H - SW/SAM', boys.wflSwSam, girls.wflSwSam, boys.wflSwSam + girls.wflSwSam),
      _buildRow('MUAC - Normal', boys.muacNormal, girls.muacNormal, boys.muacNormal + girls.muacNormal),
      _buildRow('MUAC - MW/MAM', boys.muacMwMam, girls.muacMwMam, boys.muacMwMam + girls.muacMwMam),
      _buildRow('MUAC - SW/SAM', boys.muacSwSam, girls.muacSwSam, boys.muacSwSam + girls.muacSwSam),
    ];
  }

  /// One row for Total WFA (row 33) for an age band: boys, girls, total; T and V show —.
  TableRow _buildTotalWfaRow(String cellLabel, OptPlusBoys0to5Counts boys, OptPlusBoys0to5Counts girls) {
    final boysTotal = boys.wfaNormal + boys.wfaMuw + boys.wfaSuw;
    final girlsTotal = girls.wfaNormal + girls.wfaMuw + girls.wfaSuw;
    return _buildRow(cellLabel, boysTotal, girlsTotal, boysTotal + girlsTotal);
  }

  List<TableRow> _build0to59TotalRows() {
    final t = _total0to59Values();
    const labels = [
      'T16: WFA - Normal', 'T19: WFA - MUW', 'T20: WFA - SUW',
      'T21: L/HFA - Normal', 'T22: L/HFA - Tall', 'T23: L/HFA - MSt', 'T24: L/HFA - SSt',
      'T25: WFL/H - Normal', 'T26: WFL/H - OW', 'T27: WFL/H - Ob',
      'T28: WFL/H - MW/MAM', 'T29: WFL/H - SW/SAM',
      'T30: MUAC - Normal', 'T31: MUAC - MW/MAM', 'T32: MUAC - SW/SAM',
    ];
    return List.generate(15, (i) => TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(6), child: Text(labels[i], style: const TextStyle(fontSize: 11))),
        const Padding(padding: EdgeInsets.all(6), child: Text('—', style: TextStyle(fontSize: 11))),
        const Padding(padding: EdgeInsets.all(6), child: Text('—', style: TextStyle(fontSize: 11))),
        const Padding(padding: EdgeInsets.all(6), child: Text('—', style: TextStyle(fontSize: 11))),
        Padding(padding: const EdgeInsets.all(6), child: Text('${t[i]}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
        const Padding(padding: EdgeInsets.all(6), child: Text('—', style: TextStyle(fontSize: 11))),
      ],
    ));
  }

  List<TableRow> _buildF1K0to23Rows() {
    final v = _total0to23Values();
    const labels = [
      'V16: WFA - Normal', 'V19: WFA - MUW', 'V20: WFA - SUW',
      'V21: L/HFA - Normal', 'V22: L/HFA - Tall', 'V23: L/HFA - MSt', 'V24: L/HFA - SSt',
      'V25: WFL/H - Normal', 'V26: WFL/H - OW', 'V27: WFL/H - Ob',
      'V28: WFL/H - MW/MAM', 'V29: WFL/H - SW/SAM',
      'V30: MUAC - Normal', 'V31: MUAC - MW/MAM', 'V32: MUAC - SW/SAM',
    ];
    return List.generate(15, (i) => TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(6), child: Text(labels[i], style: const TextStyle(fontSize: 11))),
        const Padding(padding: EdgeInsets.all(6), child: Text('—', style: TextStyle(fontSize: 11))),
        const Padding(padding: EdgeInsets.all(6), child: Text('—', style: TextStyle(fontSize: 11))),
        const Padding(padding: EdgeInsets.all(6), child: Text('—', style: TextStyle(fontSize: 11))),
        const Padding(padding: EdgeInsets.all(6), child: Text('—', style: TextStyle(fontSize: 11))),
        Padding(padding: const EdgeInsets.all(6), child: Text('${v[i]}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E8B7B).withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cell preview (template mapping)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: Colors.grey.shade400, width: 1),
            columnWidths: const {
              0: FlexColumnWidth(1.5),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
              5: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade200),
                children: const [
                  Padding(padding: EdgeInsets.all(8), child: Text('Cell / Label', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('B', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('C', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('D', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('T', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('V', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(8), child: Text('B9: Barangay', style: TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(8), child: Text(data.barangayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  const Padding(padding: EdgeInsets.all(8), child: Text('—', style: TextStyle(fontSize: 12))),
                  const Padding(padding: EdgeInsets.all(8), child: Text('—', style: TextStyle(fontSize: 12))),
                  const Padding(padding: EdgeInsets.all(8), child: Text('—', style: TextStyle(fontSize: 12))),
                  const Padding(padding: EdgeInsets.all(8), child: Text('—', style: TextStyle(fontSize: 12))),
                ],
              ),
              _sectionHeader('0–5 months'),
              ..._buildAgeBandRows(data.boys0to5, data.girls0to5),
              _buildTotalWfaRow('Total WFA (B33/C33/D33)', data.boys0to5, data.girls0to5),
              _sectionHeader('6–11 months'),
              ..._buildAgeBandRows(data.boys6to11, data.girls6to11),
              _buildTotalWfaRow('Total WFA (E33/F33/G33)', data.boys6to11, data.girls6to11),
              _sectionHeader('12–23 months'),
              ..._buildAgeBandRows(data.boys12to23, data.girls12to23),
              _buildTotalWfaRow('Total WFA (H33/I33/J33)', data.boys12to23, data.girls12to23),
              _sectionHeader('24–35 months'),
              ..._buildAgeBandRows(data.boys24to35, data.girls24to35),
              _buildTotalWfaRow('Total WFA (K33/L33/M33)', data.boys24to35, data.girls24to35),
              _sectionHeader('36–47 months'),
              ..._buildAgeBandRows(data.boys36to47, data.girls36to47),
              _buildTotalWfaRow('Total WFA (N33/O33/P33)', data.boys36to47, data.girls36to47),
              _sectionHeader('48–59 months'),
              ..._buildAgeBandRows(data.boys48to59, data.girls48to59),
              _buildTotalWfaRow('Total WFA (Q33/R33/S33)', data.boys48to59, data.girls48to59),
              _sectionHeader('0–59 months (Total)'),
              ..._build0to59TotalRows(),
              _sectionHeader('F1K 0–23 months (Total)'),
              ..._buildF1K0to23Rows(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Row 13 (Totals – all patients)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          const SizedBox(height: 6),
          Table(
            border: TableBorder.all(color: Colors.grey.shade400, width: 1),
            columnWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(1)},
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade200),
                children: const [
                  Padding(padding: EdgeInsets.all(8), child: Text('Cell / Label', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Value', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('D13: Total Boys', style: TextStyle(fontSize: 11))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${data.summary.totalBoys}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('G13: Total Girls', style: TextStyle(fontSize: 11))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${data.summary.totalGirls}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('J13: Total MUAC', style: TextStyle(fontSize: 11))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${_row13TotalMuac(data)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('M13: Total WFA', style: TextStyle(fontSize: 11))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${_row13TotalWfa(data)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('P13: Total HFA', style: TextStyle(fontSize: 11))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${_row13TotalHfa(data)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('S13: Total WFL/H', style: TextStyle(fontSize: 11))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${_row13TotalWfl(data)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Indicator summary (H35–H42)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          const SizedBox(height: 6),
          Table(
            border: TableBorder.all(color: Colors.grey.shade400, width: 1),
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade200),
                children: const [
                  Padding(padding: EdgeInsets.all(8), child: Text('Cell / Label', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Value', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('H35: # 0–59 mos. Wasted and/or Stunted', style: TextStyle(fontSize: 11))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${data.indicatorSummary.countWastedOrStunted0to59}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('H36: # 0–59 mos. Wasted and/or Stunted', style: TextStyle(fontSize: 11))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${data.indicatorSummary.countWastedOrStunted0to59}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('H37: # 0–59 mos. Overweight/Obesity', style: TextStyle(fontSize: 11))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${data.indicatorSummary.countOverweightObese0to59}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('H38: Total children 0–23 mos.', style: TextStyle(fontSize: 11))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${data.indicatorSummary.totalChildren0to23}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('H39: # 0–23 mos. Wasted and/or Stunted', style: TextStyle(fontSize: 11))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${data.indicatorSummary.countWastedOrStunted0to23}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('H40: Total children 0–29 mos.', style: TextStyle(fontSize: 11))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${data.indicatorSummary.totalChildren0to29}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('H41: Total children 30–59 mos.', style: TextStyle(fontSize: 11))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${data.indicatorSummary.totalChildren30to59}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('H42: Total children 24–59 mos.', style: TextStyle(fontSize: 11))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${data.indicatorSummary.totalChildren24to59}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'B9: Barangay name. Row 13: D13–S13. 0–59mo total: T16–T32. F1K 0–23mo: V16–V32. Indicator: H35–H42.',
            style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
