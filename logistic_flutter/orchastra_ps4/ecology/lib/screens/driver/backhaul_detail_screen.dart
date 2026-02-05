import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../models/backhaul_model.dart';
import '../../providers/backhaul_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/directions_service.dart';

/// Backhaul Detail Screen - Show pickup details with map and actions
class BackhaulDetailScreen extends StatefulWidget {
  final BackhaulPickup backhaul;

  const BackhaulDetailScreen({super.key, required this.backhaul});

  @override
  State<BackhaulDetailScreen> createState() => _BackhaulDetailScreenState();
}

class _BackhaulDetailScreenState extends State<BackhaulDetailScreen> {
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  DirectionsResult? _directionsResult;
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    final backhaul = widget.backhaul;
    final loc = context.read<LocationProvider>();

    // Add markers
    _markers = {
      // Driver current position
      if (loc.currentPosition != null)
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(
            loc.currentPosition!.latitude,
            loc.currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      // Pickup location
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(backhaul.shipperLat, backhaul.shipperLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Pickup: ${backhaul.shipperName}'),
      ),
    };

    // Fetch route
    if (loc.currentPosition != null) {
      final directions = await DirectionsService().getDirections(
        origin: LatLng(
          loc.currentPosition!.latitude,
          loc.currentPosition!.longitude,
        ),
        destination: LatLng(backhaul.shipperLat, backhaul.shipperLng),
      );

      if (directions != null && mounted) {
        setState(() {
          _directionsResult = directions;
          _isLoadingRoute = false;
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: directions.polylinePoints,
              color: AppColors.primary,
              width: 5,
            ),
          };
        });
      } else {
        setState(() => _isLoadingRoute = false);
      }
    } else {
      setState(() => _isLoadingRoute = false);
    }
  }

  Future<void> _openGoogleMaps() async {
    final backhaul = widget.backhaul;
    final loc = context.read<LocationProvider>();

    String url;
    if (loc.currentPosition != null) {
      url =
          'https://www.google.com/maps/dir/'
          '${loc.currentPosition!.latitude},${loc.currentPosition!.longitude}/'
          '${backhaul.shipperLat},${backhaul.shipperLng}';
    } else {
      url =
          'https://www.google.com/maps/search/?api=1&query=${backhaul.shipperLat},${backhaul.shipperLng}';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backhaul = widget.backhaul;

    return Scaffold(
      body: Consumer<BackhaulProvider>(
        builder: (context, provider, _) {
          return Stack(
            children: [
              // Map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(backhaul.shipperLat, backhaul.shipperLng),
                  zoom: 13,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),

              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: AppColors.card,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // Bottom sheet
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                                  backhaul.status,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                backhaul.statusDisplayName,
                                style: AppTextStyles.caption.copyWith(
                                  color: _getStatusColor(backhaul.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.eco_rounded,
                              size: 16,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${backhaul.carbonSavedKg.toStringAsFixed(1)} kg CO₂ saved',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Shipper info
                        Text(
                          backhaul.shipperName,
                          style: AppTextStyles.heading2,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                backhaul.shipperLocation,
                                style: AppTextStyles.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Info chips
                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.inventory_2_outlined,
                              label: '${backhaul.packageCount} pkg',
                            ),
                            const SizedBox(width: 12),
                            _InfoChip(
                              icon: Icons.scale_outlined,
                              label:
                                  '${backhaul.totalWeight.toStringAsFixed(0)} kg',
                            ),
                            const SizedBox(width: 12),
                            _InfoChip(
                              icon: Icons.straighten_outlined,
                              label: _isLoadingRoute
                                  ? 'Loading...'
                                  : _directionsResult != null
                                  ? _directionsResult!.distanceText
                                  : '${backhaul.distanceKm.toStringAsFixed(1)} km',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Navigate button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _openGoogleMaps,
                            icon: const Icon(Icons.navigation_rounded),
                            label: const Text('Open in Google Maps'),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Action buttons based on status
                        _buildActionButtons(provider, backhaul),
                      ],
                    ),
                  ),
                ),
              ),

              // Loading overlay
              if (provider.isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(
    BackhaulProvider provider,
    BackhaulPickup backhaul,
  ) {
    switch (backhaul.status) {
      case 'PROPOSED':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final success = await provider.rejectBackhaul(backhaul.id);
                  if (success && mounted) Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                ),
                child: Text(
                  'Decline',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () async {
                  final success = await provider.acceptBackhaul(backhaul.id);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Backhaul accepted!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: const Text('Accept Pickup'),
              ),
            ),
          ],
        );

      case 'ACCEPTED':
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () async {
              final success = await provider.startPickup(backhaul.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Heading to pickup...'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            child: const Text('Start Pickup'),
          ),
        );

      case 'EN_ROUTE_TO_PICKUP':
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () async {
              final success = await provider.confirmPickup(backhaul.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pickup confirmed!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Confirm Pickup'),
          ),
        );

      case 'PICKED_UP':
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () async {
              final success = await provider.completeDelivery(backhaul.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Backhaul delivery completed! +₹100 bonus'),
                    backgroundColor: AppColors.success,
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Complete Delivery'),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PROPOSED':
        return AppColors.warning;
      case 'ACCEPTED':
      case 'EN_ROUTE_TO_PICKUP':
        return AppColors.primary;
      case 'PICKED_UP':
        return AppColors.inTransit;
      case 'DELIVERED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
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
        color: AppColors.background,
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
