import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/backhaul_provider.dart';
import '../../models/backhaul_model.dart';
import 'backhaul_detail_screen.dart';

/// Backhaul List Screen - Return load opportunities
class BackhaulListScreen extends StatefulWidget {
  const BackhaulListScreen({super.key});

  @override
  State<BackhaulListScreen> createState() => _BackhaulListScreenState();
}

class _BackhaulListScreenState extends State<BackhaulListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BackhaulProvider>().fetchOpportunities();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<BackhaulProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: () => provider.fetchOpportunities(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Backhaul Pickups', style: AppTextStyles.heading1),
                        const SizedBox(height: 8),
                        Text(
                          'Return load opportunities near you',
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
                else if (provider.opportunities.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.replay_rounded,
                            size: 64,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No backhaul opportunities',
                            style: AppTextStyles.subtitle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'New opportunities will appear here',
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
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BackhaulDetailScreen(
                                  backhaul: provider.opportunities[index],
                                ),
                              ),
                            );
                          },
                          child: _BackhaulCard(
                            backhaul: provider.opportunities[index],
                            onAccept: () => provider.acceptBackhaul(
                              provider.opportunities[index].id,
                            ),
                            onReject: () => provider.rejectBackhaul(
                              provider.opportunities[index].id,
                            ),
                          ),
                        ),
                        childCount: provider.opportunities.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BackhaulCard extends StatelessWidget {
  final BackhaulPickup backhaul;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _BackhaulCard({
    required this.backhaul,
    required this.onAccept,
    required this.onReject,
  });

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  backhaul.statusDisplayName,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.eco_rounded, size: 16, color: AppColors.success),
              const SizedBox(width: 4),
              Text(
                '${backhaul.carbonSavedKg.toStringAsFixed(1)} kg CO₂',
                style: AppTextStyles.caption.copyWith(color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(backhaul.shipperName, style: AppTextStyles.heading3),
          const SizedBox(height: 4),
          Text(
            backhaul.shipperLocation,
            style: AppTextStyles.caption,
            maxLines: 1,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Info(
                icon: Icons.inventory_2_outlined,
                label: '${backhaul.packageCount} pkg',
              ),
              const SizedBox(width: 16),
              _Info(
                icon: Icons.scale_outlined,
                label: '${backhaul.totalWeight.toStringAsFixed(0)} kg',
              ),
              const SizedBox(width: 16),
              _Info(
                icon: Icons.straighten_outlined,
                label: '${backhaul.distanceKm.toStringAsFixed(1)} km',
              ),
            ],
          ),
          if (backhaul.canAccept) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
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
                    onPressed: onAccept,
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Info({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
