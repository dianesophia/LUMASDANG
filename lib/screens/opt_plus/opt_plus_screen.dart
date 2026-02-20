import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/firestore_service.dart';
import '../../services/opt_plus_service.dart';
import 'widgets/opt_plus_preview_table.dart';

class OptPlusScreen extends StatefulWidget {
  const OptPlusScreen({super.key});

  @override
  State<OptPlusScreen> createState() => _OptPlusScreenState();
}

class _OptPlusScreenState extends State<OptPlusScreen> {
  bool _isGenerating = false;
  OptPlusPreviewData? _previewData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _onMockDataToggled(bool value) {
    setState(() {
      OptPlusService.useMockData = value;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        FirestoreService().getCurrentUserBarangayName(),
        OptPlusService.buildSummary(),
        OptPlusService.buildIndicatorSummary(),
        OptPlusService.buildBoys0to5Counts(),
        OptPlusService.buildGirls0to5Counts(),
        OptPlusService.buildBoys6to11Counts(),
        OptPlusService.buildGirls6to11Counts(),
        OptPlusService.buildBoys12to23Counts(),
        OptPlusService.buildGirls12to23Counts(),
        OptPlusService.buildBoys24to35Counts(),
        OptPlusService.buildGirls24to35Counts(),
        OptPlusService.buildBoys36to47Counts(),
        OptPlusService.buildGirls36to47Counts(),
        OptPlusService.buildBoys48to59Counts(),
        OptPlusService.buildGirls48to59Counts(),
      ]);
      if (mounted) {
        setState(() {
          _previewData = OptPlusPreviewData(
            barangayName: (results[0] as String).trim().isEmpty ? '—' : results[0] as String,
            summary: results[1] as OptPlusSummary,
            indicatorSummary: results[2] as OptPlusIndicatorSummary,
            boys0to5: results[3] as OptPlusBoys0to5Counts,
            girls0to5: results[4] as OptPlusBoys0to5Counts,
            boys6to11: results[5] as OptPlusBoys0to5Counts,
            girls6to11: results[6] as OptPlusBoys0to5Counts,
            boys12to23: results[7] as OptPlusBoys0to5Counts,
            girls12to23: results[8] as OptPlusBoys0to5Counts,
            boys24to35: results[9] as OptPlusBoys0to5Counts,
            girls24to35: results[10] as OptPlusBoys0to5Counts,
            boys36to47: results[11] as OptPlusBoys0to5Counts,
            girls36to47: results[12] as OptPlusBoys0to5Counts,
            boys48to59: results[13] as OptPlusBoys0to5Counts,
            girls48to59: results[14] as OptPlusBoys0to5Counts,
          );
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _generateAndShare() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      final path = await OptPlusService.generateExcelFile();
      await Share.shareXFiles(
        [XFile(path)],
        text: 'OPT Plus summary (0–59 months)',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate OPT Plus file: $e'),
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
                      const SizedBox(height: 12),
                      _buildContent(),
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
                  'OPT PLUS',
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
                    decoration: BoxDecoration(color: Colors.purpleAccent),
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
          const Icon(Icons.table_chart, size: 48, color: Color(0xFF2E8B7B)),
          const SizedBox(height: 8),
          const Text(
            'OPT Plus Summary Sheet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2E8B7B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Preview of data that will be written to the template:',
            style: TextStyle(fontSize: 12, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.science, size: 18, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text('Use mock data', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              Switch(
                value: OptPlusService.useMockData,
                onChanged: _onMockDataToggled,
                activeTrackColor: const Color(0xFF2E8B7B).withValues(alpha: 0.5),
                activeThumbColor: const Color(0xFF2E8B7B),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E8B7B)),
          ),
        ),
      );
    }
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 40),
            const SizedBox(height: 8),
            Text(
              'Could not load summary: $_error',
              style: TextStyle(fontSize: 12, color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_previewData != null) {
      return OptPlusPreviewTable(data: _previewData!);
    }
    return const SizedBox.shrink();
  }

  Widget _buildGenerateButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isGenerating ? null : _generateAndShare,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2E8B7B),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 4,
          ),
          icon: _isGenerating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E8B7B)),
                  ),
                )
              : const Icon(Icons.print),
          label: Text(
            _isGenerating ? 'Generating…' : 'Generate & Share Excel',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
