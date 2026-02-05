import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/absorption_provider.dart';

/// Absorption Importer Screen - Scan QR and verify cargo
class AbsorptionImporterScreen extends StatefulWidget {
  const AbsorptionImporterScreen({super.key});

  @override
  State<AbsorptionImporterScreen> createState() =>
      _AbsorptionImporterScreenState();
}

class _AbsorptionImporterScreenState extends State<AbsorptionImporterScreen> {
  MobileScannerController _controller = MobileScannerController();
  bool _isScanned = false;
  bool _isVerifying = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onScan(BarcodeCapture capture) async {
    if (_isScanned || capture.barcodes.isEmpty) return;
    final barcode = capture.barcodes.first;
    if (barcode.rawValue == null) return;

    setState(() {
      _isScanned = true;
      _isVerifying = true;
    });

    final success = await context.read<AbsorptionProvider>().verifyQRCode(
      barcode.rawValue!,
    );
    setState(() => _isVerifying = false);

    if (success && mounted) {
      _showSuccess();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isScanned = false);
    }
  }

  void _showSuccess() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            Text('QR Verified!', style: AppTextStyles.heading2),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Complete'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onScan),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (_isVerifying)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
