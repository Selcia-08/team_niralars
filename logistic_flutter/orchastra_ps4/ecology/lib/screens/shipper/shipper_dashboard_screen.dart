import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shipment_provider.dart';
import '../auth/phone_login_screen.dart';
import 'create_shipment_screen.dart';
import 'track_shipment_screen.dart';
import 'shipment_detail_screen.dart';

/// Shipper Dashboard Screen
class ShipperDashboardScreen extends StatefulWidget {
  const ShipperDashboardScreen({super.key});

  @override
  State<ShipperDashboardScreen> createState() => _ShipperDashboardScreenState();
}

class _ShipperDashboardScreenState extends State<ShipperDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _ShipperHomeTab(),
          _ShipmentsTab(),
          _ShipperProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_rounded),
            label: 'Shipments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _ShipperHomeTab extends StatelessWidget {
  const _ShipperHomeTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      user?.displayInitials ?? 'S',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${user?.name ?? 'Shipper'}',
                      style: AppTextStyles.subtitle,
                    ),
                    Text('Welcome back!', style: AppTextStyles.heading3),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Quick actions
            Text('Quick Actions', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            Row(
              children: [
                _ActionCard(
                  icon: Icons.add_box_rounded,
                  label: 'New Shipment',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateShipmentScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _ActionCard(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Track',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrackShipmentScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            Text('Recent Shipments', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            _EmptyState(message: 'No recent shipments'),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(label, style: AppTextStyles.body),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShipmentsTab extends StatefulWidget {
  const _ShipmentsTab();

  @override
  State<_ShipmentsTab> createState() => _ShipmentsTabState();
}

class _ShipmentsTabState extends State<_ShipmentsTab> {
  @override
  void initState() {
    super.initState();
    // Schedule fetch after build completes to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShipmentProvider>().fetchMyShipments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<ShipmentProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: () => provider.fetchMyShipments(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('My Shipments', style: AppTextStyles.heading1),
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
                else if (provider.shipments.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 64,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No shipments yet',
                            style: AppTextStyles.subtitle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first shipment',
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
                        final shipment = provider.shipments[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ShipmentDetailScreen(shipment: shipment),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          shipment.status,
                                        ).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        shipment.statusDisplayName,
                                        style: AppTextStyles.caption.copyWith(
                                          color: _getStatusColor(
                                            shipment.status,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      shipment.id.substring(
                                        0,
                                        shipment.id.length > 8
                                            ? 8
                                            : shipment.id.length,
                                      ),
                                      style: AppTextStyles.caption,
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: AppColors.textMuted,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Column(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 10,
                                          color: AppColors.success,
                                        ),
                                        Container(
                                          width: 2,
                                          height: 24,
                                          color: AppColors.cardLight,
                                        ),
                                        Icon(
                                          Icons.circle,
                                          size: 10,
                                          color: AppColors.error,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            shipment.pickupLocation,
                                            style: AppTextStyles.body,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 16),
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
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.category_outlined,
                                      size: 14,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      shipment.cargoType,
                                      style: AppTextStyles.caption,
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.scale_outlined,
                                      size: 14,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${shipment.cargoWeight} tonnes',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }, childCount: provider.shipments.length),
                    ),
                  ),
              ],
            ),
          );
        },
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
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }
}

class _ShipperProfileTab extends StatelessWidget {
  const _ShipperProfileTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  user?.displayInitials ?? 'S',
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.background,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(user?.name ?? 'Shipper', style: AppTextStyles.heading2),
            Text(user?.phone ?? '', style: AppTextStyles.caption),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PhoneLoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: Text('Logout', style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.subtitle),
        ],
      ),
    );
  }
}
