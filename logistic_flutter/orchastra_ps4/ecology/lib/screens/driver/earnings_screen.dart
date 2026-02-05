import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/earnings_provider.dart';

/// Earnings Screen - Transaction history and summary
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<EarningsProvider>().fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<EarningsProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: () => provider.fetchTransactions(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Earnings', style: AppTextStyles.heading1),
                        const SizedBox(height: 24),

                        // Summary cards
                        Row(
                          children: [
                            _SummaryCard(
                              label: 'Today',
                              amount: provider.todayEarnings,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 12),
                            _SummaryCard(
                              label: 'This Week',
                              amount: provider.weeklyEarnings,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _TotalCard(amount: provider.totalEarnings),
                        const SizedBox(height: 24),

                        Text(
                          'Recent Transactions',
                          style: AppTextStyles.heading3,
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
                else if (provider.transactions.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions yet',
                            style: AppTextStyles.subtitle,
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
                        (context, index) => _TransactionItem(
                          transaction: provider.transactions[index],
                        ),
                        childCount: provider.transactions.length,
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

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: 8),
            Text(
              '₹${amount.toInt()}',
              style: AppTextStyles.heading2.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double amount;
  const _TotalCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Earnings',
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${amount.toInt()}',
            style: AppTextStyles.heading1.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final dynamic transaction;
  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.amount >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.success : AppColors.error)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPositive ? Icons.arrow_downward : Icons.arrow_upward,
              color: isPositive ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.typeDisplayName, style: AppTextStyles.body),
                Text(
                  DateFormat('dd MMM, hh:mm a').format(transaction.createdAt),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}₹${transaction.amount.abs().toInt()}',
            style: AppTextStyles.heading3.copyWith(
              color: isPositive ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
