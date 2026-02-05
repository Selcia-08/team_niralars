import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../models/shipment_model.dart';
import '../../providers/shipment_provider.dart';

/// Shipment Detail Screen - Shows shipment info and live tracking
class ShipmentDetailScreen extends StatefulWidget {
  final Shipment shipment;

  const ShipmentDetailScreen({super.key, required this.shipment});

  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  late Shipment _shipment;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _shipment = widget.shipment;
    _setupMap();
    _refreshShipment();
  }

  void _setupMap() {
    _markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(_shipment.pickupLat, _shipment.pickupLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup'),
      ),
      Marker(
        markerId: const MarkerId('drop'),
        position: LatLng(_shipment.dropLat, _shipment.dropLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Drop'),
      ),
      // Driver location marker (if available)
      if (_shipment.hasDriverLocation)
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(_shipment.driverLat!, _shipment.driverLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: 'Driver: ${_shipment.driverName ?? "On the way"}',
          ),
        ),
    };

    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(_shipment.pickupLat, _shipment.pickupLng),
          LatLng(_shipment.dropLat, _shipment.dropLng),
        ],
        color: AppColors.primary,
        width: 4,
      ),
    };
  }

  Future<void> _refreshShipment() async {
    final provider = context.read<ShipmentProvider>();
    final updated = await provider.trackShipment(_shipment.id);
    if (updated != null && mounted) {
      setState(() {
        _shipment = updated;
        _setupMap(); // Refresh markers including driver location
      });
    }
  }

  void _callDriver() async {
    if (_shipment.driverPhone == null) return;
    final url = Uri.parse('tel:${_shipment.driverPhone}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_shipment.pickupLat, _shipment.pickupLng),
              zoom: 12,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: CircleAvatar(
              backgroundColor: AppColors.card,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Bottom sheet
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            builder: (context, controller) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  controller: controller,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.cardLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Status badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  _shipment.status,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _shipment.statusDisplayName,
                                style: AppTextStyles.body.copyWith(
                                  color: _getStatusColor(_shipment.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _refreshShipment,
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Shipment ID
                        Text('Shipment ID', style: AppTextStyles.caption),
                        Text(_shipment.id, style: AppTextStyles.body),
                        const SizedBox(height: 16),

                        // Route
                        _RouteCard(shipment: _shipment),
                        const SizedBox(height: 16),

                        // Cargo details
                        Text('Cargo Details', style: AppTextStyles.heading3),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.category_outlined,
                              label: _shipment.cargoType,
                            ),
                            const SizedBox(width: 12),
                            _InfoChip(
                              icon: Icons.scale_outlined,
                              label: '${_shipment.cargoWeight} tonnes',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Driver info (if assigned)
                        if (_shipment.hasDriver) ...[
                          Text('Driver Details', style: AppTextStyles.heading3),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _shipment.driverName
                                                  ?.substring(0, 1)
                                                  .toUpperCase() ??
                                              'D',
                                          style: AppTextStyles.heading2
                                              .copyWith(
                                                color: AppColors.background,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _shipment.driverName ?? 'Driver',
                                            style: AppTextStyles.body,
                                          ),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star_rounded,
                                                size: 14,
                                                color: AppColors.warning,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${_shipment.driverRating?.toStringAsFixed(1) ?? "N/A"}',
                                                style: AppTextStyles.caption,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_shipment.driverPhone != null)
                                      IconButton(
                                        onPressed: _callDriver,
                                        icon: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.success
                                                .withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.call_rounded,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (_shipment.truckLicensePlate != null) ...[
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.local_shipping_rounded,
                                        size: 18,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _shipment.truckLicensePlate!,
                                        style: AppTextStyles.body,
                                      ),
                                      if (_shipment.truckModel != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '• ${_shipment.truckModel}',
                                          style: AppTextStyles.caption,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ] else if (_shipment.isAssigned ||
                            _shipment.isInTransit) ...[
                          Text('Driver Details', style: AppTextStyles.heading3),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: AppColors.background,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Driver Assigned',
                                        style: AppTextStyles.body,
                                      ),
                                      Text(
                                        'On the way',
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (_shipment.isPending) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Waiting for driver to accept',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (_shipment.isDelivered) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Shipment delivered successfully!',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
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
        return AppColors.primary;
      case 'IN_TRANSIT':
        return AppColors.inTransit;
      case 'DELIVERED':
      case 'COMPLETED':
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }
}

class _RouteCard extends StatelessWidget {
  final Shipment shipment;

  const _RouteCard({required this.shipment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Column(
            children: [
              const Icon(Icons.circle, size: 12, color: AppColors.success),
              Container(width: 2, height: 32, color: AppColors.cardLight),
              const Icon(Icons.circle, size: 12, color: AppColors.error),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pickup', style: AppTextStyles.caption),
                Text(
                  shipment.pickupLocation,
                  style: AppTextStyles.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text('Drop', style: AppTextStyles.caption),
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
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
