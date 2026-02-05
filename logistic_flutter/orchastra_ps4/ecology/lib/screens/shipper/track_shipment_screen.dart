import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/shipment_provider.dart';
import '../../models/shipment_model.dart';

/// Track Shipment Screen - Enter tracking ID or scan QR
class TrackShipmentScreen extends StatefulWidget {
  const TrackShipmentScreen({super.key});

  @override
  State<TrackShipmentScreen> createState() => _TrackShipmentScreenState();
}

class _TrackShipmentScreenState extends State<TrackShipmentScreen> {
  final _trackingController = TextEditingController();
  Shipment? _trackedShipment;
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  Future<void> _trackShipment() async {
    if (_trackingController.text.isEmpty) {
      setState(() => _error = 'Please enter a tracking ID');
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    final provider = context.read<ShipmentProvider>();
    final shipment = await provider.trackShipment(_trackingController.text);

    setState(() {
      _isSearching = false;
      _trackedShipment = shipment;
      if (shipment == null) {
        _error = 'Shipment not found';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Shipment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter Tracking ID', style: AppTextStyles.heading3),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _trackingController,
                    decoration: InputDecoration(
                      hintText: 'e.g., SHP-123456',
                      prefixIcon: const Icon(Icons.search_rounded),
                      errorText: _error,
                    ),
                    onSubmitted: (_) => _trackShipment(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _trackShipment,
                    child: _isSearching
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.background,
                            ),
                          )
                        : const Text('Track'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            if (_trackedShipment != null) ...[
              _ShipmentTrackingCard(shipment: _trackedShipment!),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 80,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter a tracking ID to track your shipment',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShipmentTrackingCard extends StatelessWidget {
  final Shipment shipment;

  const _ShipmentTrackingCard({required this.shipment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(shipment.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  shipment.statusDisplayName,
                  style: AppTextStyles.caption.copyWith(
                    color: _getStatusColor(shipment.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'ID: ${shipment.id.substring(0, 8)}...',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Route display
          Row(
            children: [
              Column(
                children: [
                  Icon(Icons.circle, size: 12, color: AppColors.success),
                  Container(width: 2, height: 40, color: AppColors.cardLight),
                  Icon(Icons.circle, size: 12, color: AppColors.error),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From', style: AppTextStyles.caption),
                    Text(
                      shipment.pickupLocation,
                      style: AppTextStyles.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 24),
                    Text('To', style: AppTextStyles.caption),
                    Text(
                      shipment.dropLocation,
                      style: AppTextStyles.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cargo details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(
                  icon: Icons.category_outlined,
                  label: shipment.cargoType,
                ),
                _InfoItem(
                  icon: Icons.scale_outlined,
                  label: '${shipment.cargoWeight.toStringAsFixed(0)} kg',
                ),
                if (shipment.cargoVolume != null)
                  _InfoItem(
                    icon: Icons.straighten_outlined,
                    label: '${shipment.cargoVolume!.toStringAsFixed(0)} L',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppColors.warning;
      case 'ASSIGNED':
      case 'PICKED_UP':
        return AppColors.primary;
      case 'IN_TRANSIT':
        return AppColors.inTransit;
      case 'DELIVERED':
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
