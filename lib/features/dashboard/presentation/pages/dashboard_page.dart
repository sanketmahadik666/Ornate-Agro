import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../shared/domain/entities/farmer_entity.dart';
import '../../../../shared/domain/entities/distribution_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../farmers/presentation/bloc/farmer_bloc.dart';
import '../../../distribution/presentation/bloc/distribution_bloc.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Ensure data is loaded
    context.read<FarmerBloc>().add(const FarmerLoadRequested());
    context.read<DistributionBloc>().add(const DistributionLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState.status != AuthStatus.authenticated) {
            return const Center(child: Text('Not authenticated'));
          }

          return BlocBuilder<FarmerBloc, FarmerState>(
            builder: (context, farmerState) {
              return BlocBuilder<DistributionBloc, DistributionState>(
                builder: (context, distState) {
                  if (farmerState.status == FarmerStatus.loading ||
                      distState.status == DistributionBlocStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final farmers = farmerState.farmers ?? [];
                  final distributions = distState.distributions ?? [];

                  return RefreshIndicator(
                    onRefresh: () async {
                      context
                          .read<FarmerBloc>()
                          .add(const FarmerLoadRequested());
                      context
                          .read<DistributionBloc>()
                          .add(const DistributionLoadRequested());
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildGreeting(authState.user?.username ?? 'User'),
                        const SizedBox(height: 24),
                        _buildKPISection(farmers, distributions),
                        const SizedBox(height: 24),
                        _buildClassificationBreakdown(farmers),
                        const SizedBox(height: 24),
                        _buildAlertsSection(farmers, distributions),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text('Quick Actions',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        _buildQuickActions(context),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGreeting(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back,',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(name,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildKPISection(
      List<FarmerEntity> farmers, List<DistributionEntity> distributions) {
    // Computations
    final totalFarmers = farmers.length;
    double totalSeedsDistributed = 0;
    double totalYieldReturned = 0;

    for (var d in distributions) {
      totalSeedsDistributed += d.quantityDistributed;
      totalYieldReturned += d.quantityReturned;
    }

    final returnRate = totalSeedsDistributed > 0
        ? (totalYieldReturned / totalSeedsDistributed) * 100
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: _KPICard(
            title: 'Total Farmers',
            value: totalFarmers.toString(),
            icon: Icons.groups,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KPICard(
            title: 'Seeds Distributed',
            value: NumberFormat.compact().format(totalSeedsDistributed),
            icon: Icons.agriculture,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KPICard(
            title: 'Yield Return',
            value: '${returnRate.toStringAsFixed(1)}%',
            icon: Icons.trending_up,
            color: returnRate >= 80 ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildClassificationBreakdown(List<FarmerEntity> farmers) {
    int regular = 0;
    int sleepy = 0;
    int blacklist = 0;
    int reminder = 0;

    for (var f in farmers) {
      switch (f.classification) {
        case FarmerClassification.regular:
          regular++;
          break;
        case FarmerClassification.sleepy:
          sleepy++;
          break;
        case FarmerClassification.blacklist:
          blacklist++;
          break;
        case FarmerClassification.reminder:
          reminder++;
          break;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Farmer Classification',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ClassificationIndicator(
                    label: 'Regular', count: regular, color: Colors.green),
                _ClassificationIndicator(
                    label: 'Sleepy', count: sleepy, color: Colors.orange),
                _ClassificationIndicator(
                    label: 'Reminder', count: reminder, color: Colors.blue),
                _ClassificationIndicator(
                    label: 'Blacklist', count: blacklist, color: Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection(
      List<FarmerEntity> farmers, List<DistributionEntity> distributions) {
    final now = DateTime.now();

    // 1. Distributions overdue
    final overdueDistributions = distributions.where((d) {
      return d.status != DistributionStatus.fulfilled &&
          d.expectedYieldDueDate.isBefore(now);
    }).toList();

    // 2. Distributions approaching due date (within 7 days)
    final approachingDistributions = distributions.where((d) {
      if (d.status == DistributionStatus.fulfilled) return false;
      if (d.expectedYieldDueDate.isBefore(now)) return false; // Already overdue
      final daysUntilDue = d.expectedYieldDueDate.difference(now).inDays;
      return daysUntilDue >= 0 && daysUntilDue <= 7;
    }).toList();

    if (overdueDistributions.isEmpty && approachingDistributions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Action Needed',
                style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 16),
        if (overdueDistributions.isNotEmpty)
          _AlertBanner(
            title: '${overdueDistributions.length} Overdue Yield Returns',
            subtitle:
                'These distributions have passed their expected return date without full fulfillment.',
            icon: Icons.error_outline,
            color: Colors.red,
            onTap: () => Navigator.pushNamed(context,
                AppRouter.distribution), // Ideally deep link with filter
          ),
        if (approachingDistributions.isNotEmpty) ...[
          if (overdueDistributions.isNotEmpty) const SizedBox(height: 12),
          _AlertBanner(
            title: '${approachingDistributions.length} Yields Due Soon',
            subtitle: 'Harvest period ending within the next 7 days.',
            icon: Icons.schedule,
            color: Colors.orange,
            onTap: () => Navigator.pushNamed(context, AppRouter.distribution),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      children: [
        _QuickActionButton(
          title: 'Farmers',
          icon: Icons.people_alt,
          onTap: () =>
              Navigator.pushNamed(context, AppRouter.farmersByCategory),
        ),
        _QuickActionButton(
          title: 'Distributions',
          icon: Icons.local_shipping,
          onTap: () => Navigator.pushNamed(context, AppRouter.distribution),
        ),
        _QuickActionButton(
          title: 'Yield Returns',
          icon: Icons.assignment_returned,
          onTap: () => Navigator.pushNamed(context, AppRouter.yieldTracking),
        ),
        _QuickActionButton(
          title: 'Contact Logs',
          icon: Icons.contact_phone,
          onTap: () => Navigator.pushNamed(context, AppRouter.contactLog),
        ),
        _QuickActionButton(
          title: 'Reports',
          icon: Icons.analytics,
          onTap: () => Navigator.pushNamed(context, AppRouter.reports),
        ),
        _QuickActionButton(
          title: 'Crop Config',
          icon: Icons.settings,
          onTap: () => Navigator.pushNamed(context, AppRouter.cropConfig),
        ),
      ],
    );
  }
}

class _KPICard extends StatelessWidget {
  const _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ClassificationIndicator extends StatelessWidget {
  const _ClassificationIndicator({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
