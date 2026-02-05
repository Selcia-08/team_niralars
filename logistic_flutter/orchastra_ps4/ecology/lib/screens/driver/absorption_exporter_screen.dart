import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/app_theme.dart';
import '../../providers/absorption_provider.dart';
import '../../providers/delivery_provider.dart';

/// Absorption Exporter Screen - Generate QR for cargo handover
class AbsorptionExporterScreen extends StatefulWidget {
  const AbsorptionExporterScreen({super.key});

  @override
  State<AbsorptionExporterScreen> createState() =>
      _AbsorptionExporterScreenState();
}

class _AbsorptionExporterScreenState extends State<AbsorptionExporterScreen> {
  String? _qrData;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _generateQR();
  }

  Future<void> _generateQR() async {
    setState(() => _isGenerating = true);

    final absorptionProvider = context.read<AbsorptionProvider>();
    final transfer = absorptionProvider.currentTransfer;

    if (transfer != null) {
      final qrData = await absorptionProvider.generateQRCode(transfer.id);
      setState(() {
        _qrData = qrData;
        _isGenerating = false;
      });
    } else {
      // Generate a demo QR for testing
      setState(() {
        _qrData = 'ECOLOGIQ_TRANSFER_${DateTime.now().millisecondsSinceEpoch}';
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final delivery = context.watch<DeliveryProvider>().activeDelivery;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cargo Handover'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Show this QR code to the receiving driver to transfer cargo',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // QR Code
              if (_isGenerating)
                const SizedBox(
                  width: 240,
                  height: 240,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_qrData != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: QrImageView(
                    data: _qrData!,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                  ),
                )
              else
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(child: Text('Failed to generate QR')),
                ),

              const SizedBox(height: 32),

              // Transfer details
              if (delivery != null) ...[
                Text('Transfer Details', style: AppTextStyles.heading3),
                const SizedBox(height: 16),

                _DetailRow(label: 'Package ID', value: delivery.packageId),
                _DetailRow(label: 'Cargo Type', value: delivery.cargoType),
                _DetailRow(
                  label: 'Weight',
                  value: '${delivery.cargoWeight.toStringAsFixed(1)} kg',
                ),
                _DetailRow(label: 'Destination', value: delivery.dropLocation),
              ],

              const Spacer(),

              // Regenerate button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isGenerating ? null : _generateQR,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Regenerate QR Code'),
                ),
              ),

              const SizedBox(height: 12),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel Transfer',
                    style: AppTextStyles.body.copyWith(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detail row widget
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.body,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
