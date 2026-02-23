import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/lumasdang_records_service.dart';

class LumasdangRecordsScreen extends StatefulWidget {
  const LumasdangRecordsScreen({super.key});

  @override
  State<LumasdangRecordsScreen> createState() => _LumasdangRecordsScreenState();
}

class _LumasdangRecordsScreenState extends State<LumasdangRecordsScreen> {
  bool _isGenerating = false;

  Future<void> _generateAndShare() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      final path = await LumasdangRecordsService.generateExcelFile();
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Lumasdang records (child list with assessments)',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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
            onPressed: () => Navigator.of(context).pop(),
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
          onPressed: _isGenerating ? null : _generateAndShare,
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
          label: Text(_isGenerating ? 'Generating…' : 'Generate & Share Excel'),
        ),
      ),
    );
  }
}
