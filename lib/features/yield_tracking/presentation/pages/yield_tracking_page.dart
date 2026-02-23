import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/domain/entities/distribution_entity.dart';
import '../../../../shared/domain/entities/farmer_entity.dart';
import '../../../distribution/presentation/bloc/distribution_bloc.dart';
import '../../../farmers/presentation/bloc/farmer_bloc.dart';

class YieldTrackingPage extends StatefulWidget {
  const YieldTrackingPage({super.key});

  @override
  State<YieldTrackingPage> createState() => _YieldTrackingPageState();
}

class _YieldTrackingPageState extends State<YieldTrackingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<DistributionBloc>().add(const DistributionLoadRequested());
    context.read<FarmerBloc>().add(const FarmerLoadRequested());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getFarmerName(String id, List<FarmerEntity> farmers) {
    try {
      return farmers.firstWhere((f) => f.id == id).fullName;
    } catch (_) {
      return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yield Return Tracking'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Action Needed', icon: Icon(Icons.warning_amber)),
            Tab(text: 'Pending', icon: Icon(Icons.hourglass_empty)),
            Tab(text: 'Fulfilled', icon: Icon(Icons.check_circle_outline)),
          ],
        ),
      ),
      body: BlocConsumer<DistributionBloc, DistributionState>(
        listener: (context, state) {
          if (state.status == DistributionBlocStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Error'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state.status == DistributionBlocStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.successMessage ?? 'Success')),
            );
          }
        },
        builder: (context, dState) {
          return BlocBuilder<FarmerBloc, FarmerState>(
            builder: (context, fState) {
              if (dState.status == DistributionBlocStatus.loading ||
                  fState.status == FarmerStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              final distributions = dState.distributions ?? [];
              final farmers = fState.farmers ?? [];

              final actionNeeded = distributions
                  .where((d) =>
                      d.status == DistributionStatus.overdue ||
                      d.status == DistributionStatus.due)
                  .toList();

              final pending = distributions
                  .where((d) =>
                      d.status == DistributionStatus.pending ||
                      d.status == DistributionStatus.partiallyFulfilled)
                  .toList();

              final fulfilled = distributions
                  .where((d) => d.status == DistributionStatus.fulfilled)
                  .toList();

              return Column(
                children: [
                  _buildSummaryCards(actionNeeded, pending),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(actionNeeded, farmers,
                            showRecordButton: true),
                        _buildList(pending, farmers, showRecordButton: true),
                        _buildList(fulfilled, farmers, showRecordButton: false),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(
      List<DistributionEntity> actionNeeded, List<DistributionEntity> pending) {
    double actionOutstanding = 0;
    for (var d in actionNeeded) {
      actionOutstanding += d.outstandingQuantity;
    }

    double pendingOutstanding = 0;
    for (var d in pending) {
      pendingOutstanding += d.outstandingQuantity;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'Total Overdue',
              value: actionNeeded
                  .where((d) => d.status == DistributionStatus.overdue)
                  .length
                  .toString(),
              subtitle: '${actionOutstanding.toStringAsFixed(1)} qty owed',
              color: Colors.red,
              icon: Icons.assignment_late,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _SummaryCard(
              title: 'Total Pending',
              value: pending.length.toString(),
              subtitle: '${pendingOutstanding.toStringAsFixed(1)} qty owed',
              color: Colors.blue,
              icon: Icons.pending_actions,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      List<DistributionEntity> distributions, List<FarmerEntity> farmers,
      {required bool showRecordButton}) {
    if (distributions.isEmpty) {
      return Center(
        child: Text(
          'No records found.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: distributions.length,
      itemBuilder: (context, index) {
        final d = distributions[index];
        final farmerName = _getFarmerName(d.farmerId, farmers);

        Color statusColor;
        switch (d.status) {
          case DistributionStatus.pending:
            statusColor = Colors.blue;
            break;
          case DistributionStatus.due:
            statusColor = Colors.orange;
            break;
          case DistributionStatus.partiallyFulfilled:
            statusColor = Colors.amber;
            break;
          case DistributionStatus.fulfilled:
            statusColor = Colors.green;
            break;
          case DistributionStatus.overdue:
            statusColor = Colors.red;
            break;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: Border(left: BorderSide(color: statusColor, width: 4)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.1),
              child: Icon(Icons.agriculture, color: statusColor),
            ),
            title: Text(farmerName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                '${d.seedType} • Due: ${_dateFormat.format(d.expectedYieldDueDate)}'),
            trailing: Chip(
              label: Text(
                d.status.name.toUpperCase(),
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              backgroundColor: statusColor.withValues(alpha: 0.1),
              labelStyle: TextStyle(color: statusColor),
              side: BorderSide.none,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat(
                            'Distributed', '${d.quantityDistributed} (qty)'),
                        _buildStat('Returned', '${d.quantityReturned} (qty)'),
                        _buildStat(
                            'Outstanding', '${d.outstandingQuantity} (qty)',
                            isAlert: d.outstandingQuantity > 0),
                      ],
                    ),
                    if (showRecordButton) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _showYieldReturnBottomSheet(
                              context, d, farmerName),
                          icon: const Icon(Icons.assignment_turned_in),
                          label: const Text('Record Return'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Clinchit (force-fulfill) button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showClinchitDialog(context, d, farmerName),
                              icon: const Icon(Icons.check_circle,
                                  color: Colors.green),
                              label: const Text('Clinchit',
                                  style: TextStyle(color: Colors.green)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.green),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Blacklist authority button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showBlacklistDialog(context, d, farmerName),
                              icon: const Icon(Icons.block, color: Colors.red),
                              label: const Text('Blacklist',
                                  style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStat(String label, String value, {bool isAlert = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isAlert ? Colors.red.shade700 : null,
          ),
        ),
      ],
    );
  }

  void _showYieldReturnBottomSheet(BuildContext context,
      DistributionEntity distribution, String farmerName) {
    final qtyController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Record Yield Return',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Farmer: $farmerName\nOwed: ${distribution.outstandingQuantity} qty',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: qtyController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Quantity Returned',
                    prefixIcon: const Icon(Icons.scale),
                    border: const OutlineInputBorder(),
                    helperText: 'Max: ${distribution.outstandingQuantity} qty',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final val = double.tryParse(v);
                    if (val == null || val <= 0) return 'Must be positive';
                    if (val > distribution.outstandingQuantity) {
                      return 'Cannot return more than ${distribution.outstandingQuantity}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final val = double.parse(qtyController.text);
                      context
                          .read<DistributionBloc>()
                          .add(DistributionYieldReturnRequested(
                            id: distribution.id,
                            quantityReturned: val,
                            staffId: 'STAFF_001',
                          ));
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save Return'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Clinchit — authority force-fulfills a distribution.
  void _showClinchitDialog(BuildContext context,
      DistributionEntity distribution, String farmerName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Clinchit – Force Fulfill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Farmer: $farmerName'),
            Text('Seed: ${distribution.seedType}'),
            Text(
                'Outstanding: ${distribution.outstandingQuantity.toStringAsFixed(1)} qty'),
            const SizedBox(height: 12),
            const Text(
              'This will mark the distribution as fully fulfilled, '
              'writing off the outstanding quantity. '
              'This action requires authority approval.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DistributionBloc>().add(
                    DistributionForceFullfillRequested(
                      id: distribution.id,
                      authorityId: 'AUTHORITY_001',
                    ),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        '$farmerName distribution force-fulfilled (Clinchit)')),
              );
            },
            child: const Text('Confirm Clinchit'),
          ),
        ],
      ),
    );
  }

  /// Blacklist — authority moves farmer to blacklist.
  void _showBlacklistDialog(BuildContext context,
      DistributionEntity distribution, String farmerName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.block, color: Colors.red, size: 48),
        title: const Text('Move to Blacklist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Farmer: $farmerName'),
            Text(
                'Outstanding: ${distribution.outstandingQuantity.toStringAsFixed(1)} qty'),
            const SizedBox(height: 12),
            const Text(
              'This will blacklist the farmer. Blacklisted farmers '
              'will not be auto-reclassified by the system. '
              'Only an authority can reverse this action.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              // Get farmers from the farmer bloc state
              final farmerState = context.read<FarmerBloc>().state;
              final farmers = farmerState.farmers ?? [];
              final farmer =
                  farmers.where((f) => f.id == distribution.farmerId);
              if (farmer.isNotEmpty) {
                context.read<FarmerBloc>().add(
                      FarmerUpdateRequested(
                        farmer.first.copyWith(
                          classification: FarmerClassification.blacklist,
                          updatedAt: DateTime.now(),
                        ),
                      ),
                    );
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$farmerName moved to Blacklist')),
              );
            },
            child: const Text('Confirm Blacklist'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}
