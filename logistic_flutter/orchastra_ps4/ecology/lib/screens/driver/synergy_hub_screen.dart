import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../providers/absorption_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/location_provider.dart';

/// Synergy Hub Screen - QR Generation, QR Scanning, and Navigation
class SynergyHubScreen extends StatefulWidget {
  const SynergyHubScreen({super.key});

  @override
  State<SynergyHubScreen> createState() => _SynergyHubScreenState();
}

class _SynergyHubScreenState extends State<SynergyHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _qrData;
  bool _isGeneratingQR = false;
  bool _isScanned = false;
  bool _isVerifying = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generateQR();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _generateQR() async {
    setState(() => _isGeneratingQR = true);

    final absorptionProvider = context.read<AbsorptionProvider>();
    final delivery = context.read<DeliveryProvider>().activeDelivery;
    final transfer = absorptionProvider.currentTransfer;

    if (transfer != null) {
      final qrData = await absorptionProvider.generateQRCode(transfer.id);
      setState(() {
        _qrData = qrData;
        _isGeneratingQR = false;
      });
    } else if (delivery != null) {
      // Generate QR with delivery info for handover
      setState(() {
        _qrData =
            'ECOLOGIQ_HANDOVER|${delivery.id}|${delivery.packageId}|${DateTime.now().millisecondsSinceEpoch}';
        _isGeneratingQR = false;
      });
    } else {
      setState(() {
        _qrData = 'ECOLOGIQ_TRANSFER_${DateTime.now().millisecondsSinceEpoch}';
        _isGeneratingQR = false;
      });
    }
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
          content: Text('Invalid QR Code. Please try again.'),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 20),
            Text('Handover Verified!', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              'Cargo transfer completed successfully',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Complete'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Open Google Maps for navigation to destination
  Future<void> _openGoogleMapsNavigation() async {
    final delivery = context.read<DeliveryProvider>().activeDelivery;
    if (delivery == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No active delivery found')));
      return;
    }

    // Get current location
    final locationProvider = context.read<LocationProvider>();
    final currentPosition = locationProvider.currentPosition;

    String url;
    if (currentPosition != null) {
      // Navigation from current location to drop location
      url =
          'https://www.google.com/maps/dir/'
          '${currentPosition.latitude},${currentPosition.longitude}/'
          '${delivery.dropLat},${delivery.dropLng}';
    } else {
      // Just open drop location
      url =
          'https://www.google.com/maps/search/?api=1&query=${delivery.dropLat},${delivery.dropLng}';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  /// Open Google Maps for navigation to pickup location
  Future<void> _openGoogleMapsToPickup() async {
    final delivery = context.read<DeliveryProvider>().activeDelivery;
    if (delivery == null) return;

    final locationProvider = context.read<LocationProvider>();
    final currentPosition = locationProvider.currentPosition;

    String url;
    if (currentPosition != null) {
      url =
          'https://www.google.com/maps/dir/'
          '${currentPosition.latitude},${currentPosition.longitude}/'
          '${delivery.pickupLat},${delivery.pickupLng}';
    } else {
      url =
          'https://www.google.com/maps/search/?api=1&query=${delivery.pickupLat},${delivery.pickupLng}';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final delivery = context.watch<DeliveryProvider>().activeDelivery;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Synergy Hub'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_rounded), text: 'My QR'),
            Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'Scan QR'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Navigation buttons at top
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _NavigationButton(
                    icon: Icons.navigation_rounded,
                    label: 'Navigate to Pickup',
                    onTap: _openGoogleMapsToPickup,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NavigationButton(
                    icon: Icons.location_on_rounded,
                    label: 'Navigate to Drop',
                    onTap: _openGoogleMapsNavigation,
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: My QR Code
                _buildQRCodeTab(delivery),

                // Tab 2: Scan QR Code
                _buildScannerTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeTab(dynamic delivery) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
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

          const SizedBox(height: 32),

          // QR Code
          if (_isGeneratingQR)
            const SizedBox(
              width: 260,
              height: 260,
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
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

          const SizedBox(height: 24),

          // Transfer details
          if (delivery != null) ...[
            Text('Transfer Details', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            _DetailCard(
              items: [
                _DetailItem(label: 'Package ID', value: delivery.packageId),
                _DetailItem(label: 'Cargo Type', value: delivery.cargoType),
                _DetailItem(
                  label: 'Weight',
                  value: '${delivery.cargoWeight.toStringAsFixed(1)} kg',
                ),
                _DetailItem(label: 'Destination', value: delivery.dropLocation),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Regenerate button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isGeneratingQR ? null : _generateQR,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Regenerate QR Code'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    // Initialize scanner controller when tab is shown
    _scannerController ??= MobileScannerController();

    return Stack(
      children: [
        MobileScanner(controller: _scannerController!, onDetect: _onScan),

        // Scanner overlay
        Container(
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
          child: Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 64,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Position QR code here',
                    style: AppTextStyles.body.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Instructions at bottom
        Positioned(
          bottom: 40,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Scan the exporter driver\'s QR code to receive cargo',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Verifying overlay
        if (_isVerifying)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Verifying QR Code...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Navigation button widget
class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _NavigationButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary ? Colors.white : AppColors.textPrimary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: isPrimary ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Detail card widget
class _DetailCard extends StatelessWidget {
  final List<_DetailItem> items;

  const _DetailCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.label, style: AppTextStyles.caption),
                    Flexible(
                      child: Text(
                        item.value,
                        style: AppTextStyles.body,
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Detail item data class
class _DetailItem {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});
}
