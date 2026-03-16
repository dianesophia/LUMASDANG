import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/lumasdang_records_service.dart';
import 'lumasdang_records_download_stub.dart'
    if (dart.library.html) 'lumasdang_records_download_web.dart';

class LumasdangRecordsScreen extends StatefulWidget {
  const LumasdangRecordsScreen({super.key});

  @override
  State<LumasdangRecordsScreen> createState() => _LumasdangRecordsScreenState();
}

class _LumasdangRecordsScreenState extends State<LumasdangRecordsScreen> {
  bool _isGenerating = false;

  Future<void> _downloadExcel() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      if (kIsWeb) {
        final webResult = await LumasdangRecordsService.generateExcelBytes();
        await triggerLumasdangDownload(webResult.bytes as Uint8List, webResult.fileName);
        if (mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            const SnackBar(
              content: Text(
                'Lumasdang records downloaded. Check your browser Downloads.',
                style: TextStyle(fontSize: 13),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final path = await LumasdangRecordsService.generateExcelFile();
        final fileName = p.basename(path);
        // Save to the device's visible Downloads folder (uses MediaStore on Android)
        final saved = await copyFileIntoDownloadFolder(path, fileName);
        if (saved == true && mounted) {
          // Open the Downloads folder so the user sees the file
          await openDownloadFolder();
          if (mounted) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              SnackBar(
                content: Text(
                  'Saved: $fileName\nDownloads folder opened so you can see the file.',
                  style: const TextStyle(fontSize: 13),
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        } else {
          // Fallback: share so user can save to Files/Downloads manually
          await Share.shareXFiles(
            [XFile(path, name: fileName)],
            text: 'Lumasdang records (child list with assessments). Choose "Save to Files" or "Downloads" to save.',
          );
          if (mounted) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Choose "Save to Files" or "Downloads" to save the file to your device.',
                  style: TextStyle(fontSize: 13),
                ),
                backgroundColor: Color(0xFF2E8B7B),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate Lumasdang records file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E8B7B),
              Color(0xFF5CAA7F),
              Color(0xFF8BC88A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildIntroCard(),
                    ],
                  ),
                ),
              ),
              _buildGenerateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(this.context).pop(),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'LUMASDANG RECORDS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 4),
                SizedBox(
                  width: 80,
                  height: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.list_alt_rounded, size: 48, color: Color(0xFF2E8B7B)),
          const SizedBox(height: 8),
          const Text(
            'Lumasdang Records Template',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2E8B7B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Generates an Excel file with one row per child in your barangay: address, mother/caregiver, child name, sex, date of birth, date measured, weight, height, and auto-filled age and status columns (WFA, HFA, WFL).',
            style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isGenerating ? null : _downloadExcel,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2E8B7B),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          icon: _isGenerating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.table_chart_outlined, size: 22),
          label: Text(_isGenerating ? 'Downloading…' : 'Download Excel'),
        ),
      ),
    );
  }
}
