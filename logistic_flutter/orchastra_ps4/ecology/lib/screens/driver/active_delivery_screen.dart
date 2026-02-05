import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/directions_service.dart';
import 'synergy_hub_screen.dart';

/// Active Delivery Screen - Map + delivery actions
class ActiveDeliveryScreen extends StatefulWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  GoogleMapController? _mapController;
  final DirectionsService _directionsService = DirectionsService();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Route data from Google Directions API
  DirectionsResult? _directionsResult;
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _startTracking();
  }

  Future<void> _initializeMap() async {
    final delivery = context.read<DeliveryProvider>().activeDelivery;
    if (delivery == null) return;

    final pickupLatLng = LatLng(delivery.pickupLat, delivery.pickupLng);
    final dropLatLng = LatLng(delivery.dropLat, delivery.dropLng);

    // Set markers
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: delivery.pickupLocation,
          ),
        ),
        Marker(
          markerId: const MarkerId('drop'),
          position: dropLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: 'Drop', snippet: delivery.dropLocation),
        ),
      };
    });

    // Fetch real directions from Google Directions API
    try {
      final directions = await _directionsService.getDirections(
        origin: pickupLatLng,
        destination: dropLatLng,
      );

      if (directions != null && mounted) {
        setState(() {
          _directionsResult = directions;
          _isLoadingRoute = false;

          // Draw the actual road route polyline
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
        // Fallback to straight line if directions API fails
        setState(() {
          _isLoadingRoute = false;
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: [pickupLatLng, dropLatLng],
              color: AppColors.primary,
              width: 4,
            ),
          };
        });
      }
    } catch (e) {
      print('Error fetching directions: $e');
      setState(() {
        _isLoadingRoute = false;
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: [pickupLatLng, dropLatLng],
            color: AppColors.primary,
            width: 4,
          ),
        };
      });
    }
  }

  void _startTracking() {
    final locationProvider = context.read<LocationProvider>();
    locationProvider.startTracking();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _setMapStyle();
    _fitBounds();
  }

  Future<void> _setMapStyle() async {
    // Dark mode style for maps
    const darkStyle = '''
    [
      {"elementType": "geometry", "stylers": [{"color": "#1d2c4d"}]},
      {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
      {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a3646"}]},
      {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#304a7d"}]},
      {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
      {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0e1626"}]}
    ]
    ''';
    await _mapController?.setMapStyle(darkStyle);
  }

  void _fitBounds() {
    final delivery = context.read<DeliveryProvider>().activeDelivery;
    if (delivery == null || _mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        delivery.pickupLat < delivery.dropLat
            ? delivery.pickupLat
            : delivery.dropLat,
        delivery.pickupLng < delivery.dropLng
            ? delivery.pickupLng
            : delivery.dropLng,
      ),
      northeast: LatLng(
        delivery.pickupLat > delivery.dropLat
            ? delivery.pickupLat
            : delivery.dropLat,
        delivery.pickupLng > delivery.dropLng
            ? delivery.pickupLng
            : delivery.dropLng,
      ),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  @override
  void dispose() {
    context.read<LocationProvider>().stopTracking();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<DeliveryProvider>(
        builder: (context, provider, _) {
          final delivery = provider.activeDelivery;

          if (delivery == null) {
            return const Center(child: Text('No active delivery'));
          }

          return Stack(
            children: [
              // Map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(delivery.pickupLat, delivery.pickupLng),
                  zoom: 12,
                ),
                onMapCreated: _onMapCreated,
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),

              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _CircleButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        _CircleButton(
                          icon: Icons.my_location_rounded,
                          onTap: () async {
                            final loc = context.read<LocationProvider>();
                            if (loc.currentPosition != null) {
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLng(
                                  LatLng(
                                    loc.currentPosition!.latitude,
                                    loc.currentPosition!.longitude,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom sheet
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _DeliveryBottomSheet(
                  delivery: delivery,
                  isLoading: provider.isLoading,
                  directionsResult: _directionsResult,
                  isLoadingRoute: _isLoadingRoute,
                  onStart: () => provider.startDelivery(delivery.id),
                  onPickup: () => provider.pickupCargo(delivery.id),
                  onComplete: () async {
                    final success = await provider.completeDelivery(
                      delivery.id,
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Delivery completed successfully!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      Navigator.pop(context);
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            provider.error ?? 'Failed to complete delivery',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  onSynergy: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SynergyHubScreen(),
                      ),
                    );
                  },
                  onNavigate: () async {
                    // Open Google Maps for navigation
                    final loc = context.read<LocationProvider>();
                    String url;
                    if (loc.currentPosition != null) {
                      url =
                          'https://www.google.com/maps/dir/'
                          '${loc.currentPosition!.latitude},${loc.currentPosition!.longitude}/'
                          '${delivery.dropLat},${delivery.dropLng}';
                    } else {
                      url =
                          'https://www.google.com/maps/search/?api=1&query=${delivery.dropLat},${delivery.dropLng}';
                    }
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Circle button for map controls
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary),
      ),
    );
  }
}

/// Bottom sheet with delivery info and actions
class _DeliveryBottomSheet extends StatelessWidget {
  final dynamic delivery;
  final bool isLoading;
  final DirectionsResult? directionsResult;
  final bool isLoadingRoute;
  final VoidCallback onStart;
  final VoidCallback onPickup;
  final VoidCallback onComplete;
  final VoidCallback onSynergy;
  final VoidCallback onNavigate;

  const _DeliveryBottomSheet({
    required this.delivery,
    required this.isLoading,
    this.directionsResult,
    this.isLoadingRoute = true,
    required this.onStart,
    required this.onPickup,
    required this.onComplete,
    required this.onSynergy,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            const SizedBox(height: 16),

            // Status and earnings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    delivery.statusDisplayName,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '₹${delivery.totalEarnings.toInt()}',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Route
            _RouteInfo(
              pickupLocation: delivery.pickupLocation,
              dropLocation: delivery.dropLocation,
            ),

            const SizedBox(height: 20),

            // Cargo info with real distance/time from Google Directions
            Row(
              children: [
                _InfoChip(
                  icon: Icons.inventory_2_outlined,
                  label: '${delivery.cargoWeight.toStringAsFixed(1)} kg',
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.straighten_outlined,
                  label: isLoadingRoute
                      ? 'Loading...'
                      : directionsResult != null
                      ? directionsResult!.distanceText
                      : '${delivery.distanceKm?.toStringAsFixed(1) ?? '-'} km',
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.access_time_rounded,
                  label: isLoadingRoute
                      ? 'Calculating...'
                      : directionsResult != null
                      ? directionsResult!.durationText
                      : 'N/A',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Navigation button (Google Maps)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onNavigate,
                icon: const Icon(Icons.navigation_rounded),
                label: const Text('Open in Google Maps'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColors.primary),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons row
            Row(
              children: [
                // Synergy button (if applicable)
                if (delivery.status == 'IN_TRANSIT' ||
                    delivery.status == 'CARGO_LOADED' ||
                    delivery.status == 'EN_ROUTE_TO_DROP')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSynergy,
                      icon: const Icon(Icons.sync_alt_rounded),
                      label: const Text('Synergy'),
                    ),
                  ),
                if (delivery.status == 'IN_TRANSIT' ||
                    delivery.status == 'CARGO_LOADED' ||
                    delivery.status == 'EN_ROUTE_TO_DROP')
                  const SizedBox(width: 12),

                // Main action button
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _getMainAction(),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.background,
                              ),
                            )
                          : Text(_getMainActionLabel()),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  VoidCallback? _getMainAction() {
    switch (delivery.status) {
      case 'ALLOCATED':
        return onStart;
      case 'EN_ROUTE_TO_PICKUP':
        return onPickup;
      case 'CARGO_LOADED':
      case 'IN_TRANSIT':
      case 'EN_ROUTE_TO_DROP':
        return onComplete;
      default:
        return null;
    }
  }

  String _getMainActionLabel() {
    switch (delivery.status) {
      case 'ALLOCATED':
        return 'Start Delivery';
      case 'EN_ROUTE_TO_PICKUP':
        return 'Confirm Pickup';
      case 'CARGO_LOADED':
      case 'IN_TRANSIT':
      case 'EN_ROUTE_TO_DROP':
        return 'Complete Delivery';
      default:
        return 'Continue';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour}:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }
}

/// Route info widget
class _RouteInfo extends StatelessWidget {
  final String pickupLocation;
  final String dropLocation;

  const _RouteInfo({required this.pickupLocation, required this.dropLocation});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            Container(width: 2, height: 32, color: AppColors.cardLight),
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pickupLocation,
                style: AppTextStyles.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Text(
                dropLocation,
                style: AppTextStyles.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Info chip widget
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
