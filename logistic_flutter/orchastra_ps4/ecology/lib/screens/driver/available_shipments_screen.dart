import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/shipment_provider.dart';
import '../../models/shipment_model.dart';

/// Available Shipments Screen - Shows pending shipment requests for drivers
class AvailableShipmentsScreen extends StatefulWidget {
  const AvailableShipmentsScreen({super.key});

  @override
  State<AvailableShipmentsScreen> createState() =>
      _AvailableShipmentsScreenState();
}

class _AvailableShipmentsScreenState extends State<AvailableShipmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShipmentProvider>().fetchPendingShipments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<ShipmentProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: () => provider.fetchPendingShipments(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Shipments',
                          style: AppTextStyles.heading1,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Accept shipments to earn more',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ),

                if (provider.isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (provider.pendingShipments.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 64,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No shipments available',
                            style: AppTextStyles.subtitle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pull down to refresh',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final shipment = provider.pendingShipments[index];
                        return _ShipmentCard(
                          shipment: shipment,
                          onAccept: () => _acceptShipment(provider, shipment),
                        );
                      }, childCount: provider.pendingShipments.length),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _acceptShipment(
    ShipmentProvider provider,
    Shipment shipment,
  ) async {
    final success = await provider.acceptShipment(shipment.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Shipment accepted! Check your deliveries.'
                : provider.error ?? 'Failed to accept',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}

class _ShipmentCard extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback onAccept;

  const _ShipmentCard({required this.shipment, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'NEW REQUEST',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.category_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(shipment.cargoType, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 16),

          // Route
          Row(
            children: [
              Column(
                children: [
                  Icon(Icons.circle, size: 10, color: AppColors.success),
                  Container(width: 2, height: 32, color: AppColors.cardLight),
                  Icon(Icons.circle, size: 10, color: AppColors.error),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shipment.pickupLocation,
                      style: AppTextStyles.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
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
          const SizedBox(height: 16),

          // Details
          Row(
            children: [
              Icon(Icons.scale_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '${shipment.cargoWeight} tonnes',
                style: AppTextStyles.caption,
              ),
              const Spacer(),
              Text(
                '₹${((shipment.cargoWeight * 1000) + 500).toInt()}',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Accept button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAccept,
              child: const Text('Accept Shipment'),
            ),
          ),
        ],
      ),
    );
  }
}
