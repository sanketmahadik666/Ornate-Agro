import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/domain/entities/distribution_entity.dart';
import '../../../../features/farmers/presentation/bloc/farmer_bloc.dart';
import '../bloc/distribution_bloc.dart';

/// Req 3: Seed distribution log with filters (date, seed type, farmer, status).
class DistributionListPage extends StatefulWidget {
  const DistributionListPage({super.key});

  @override
  State<DistributionListPage> createState() => _DistributionListPageState();
}

class _DistributionListPageState extends State<DistributionListPage> {
  final _dateFormat = DateFormat('dd MMM yyyy');

  // Filter state
  DistributionStatus? _statusFilter;
  String? _seedTypeFilter;
  String? _farmerIdFilter;
  DateTimeRange? _dateRange;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    context.read<DistributionBloc>().add(const DistributionLoadRequested());
  }

  void _applyFilters() {
    context.read<DistributionBloc>().add(DistributionFilterRequested(
          startDate: _dateRange?.start,
          endDate: _dateRange?.end,
          seedType: _seedTypeFilter,
          farmerId: _farmerIdFilter,
          status: _statusFilter,
        ));
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = null;
      _seedTypeFilter = null;
      _farmerIdFilter = null;
      _dateRange = null;
    });
    context.read<DistributionBloc>().add(const DistributionLoadRequested());
  }

  Color _statusColor(DistributionStatus status) {
    switch (status) {
      case DistributionStatus.pending:
        return Colors.blue;
      case DistributionStatus.due:
        return Colors.orange;
      case DistributionStatus.fulfilled:
        return Colors.green;
      case DistributionStatus.partiallyFulfilled:
        return Colors.amber;
      case DistributionStatus.overdue:
        return Colors.red;
    }
  }

  String _statusLabel(DistributionStatus status) {
    switch (status) {
      case DistributionStatus.pending:
        return 'Pending';
      case DistributionStatus.due:
        return 'Due';
      case DistributionStatus.fulfilled:
        return 'Fulfilled';
      case DistributionStatus.partiallyFulfilled:
        return 'Partial';
      case DistributionStatus.overdue:
        return 'Overdue';
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _applyFilters();
    }
  }

  /// Look up farmer name from FarmerBloc state.
  String _farmerName(String farmerId, BuildContext context) {
    final farmerState = context.read<FarmerBloc>().state;
    if (farmerState.farmers != null) {
      final match = farmerState.farmers!.where((f) => f.id == farmerId);
      if (match.isNotEmpty) return match.first.fullName;
    }
    return farmerId;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DistributionBloc, DistributionState>(
      listener: (context, state) {
        if (state.status == DistributionBlocStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage ?? 'Done')),
          );
        }
        if (state.status == DistributionBlocStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Seed Distribution Log'),
            actions: [
              IconButton(
                icon: Icon(_showFilters
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined),
                onPressed: () => setState(() => _showFilters = !_showFilters),
                tooltip: 'Toggle Filters',
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, '/distribution/new'),
            icon: const Icon(Icons.add),
            label: const Text('New Distribution'),
          ),
          body: Column(
            children: [
              if (_showFilters) _buildFilterPanel(),
              Expanded(child: _buildBody(state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, size: 20),
              const SizedBox(width: 8),
              Text('Filters', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              if (_statusFilter != null ||
                  _seedTypeFilter != null ||
                  _farmerIdFilter != null ||
                  _dateRange != null)
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Status filter
              DropdownButtonFormField<DistributionStatus>(
                value: _statusFilter,
                hint: const Text('Status'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('All Statuses')),
                  ...DistributionStatus.values.map((s) =>
                      DropdownMenuItem(value: s, child: Text(_statusLabel(s)))),
                ],
                onChanged: (value) {
                  setState(() => _statusFilter = value);
                  _applyFilters();
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              // Date range filter
              OutlinedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(_dateRange == null
                    ? 'Date Range'
                    : '${_dateFormat.format(_dateRange!.start)} – ${_dateFormat.format(_dateRange!.end)}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(DistributionState state) {
    if (state.status == DistributionBlocStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final distributions = state.distributions ?? [];

    if (distributions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping_outlined,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No distributions recorded yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to record a new seed distribution',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: distributions.length,
      itemBuilder: (context, index) {
        final d = distributions[index];
        return _DistributionCard(
          distribution: d,
          farmerName: _farmerName(d.farmerId, context),
          dateFormat: _dateFormat,
          statusColor: _statusColor(d.status),
          statusLabel: _statusLabel(d.status),
        );
      },
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({
    required this.distribution,
    required this.farmerName,
    required this.dateFormat,
    required this.statusColor,
    required this.statusLabel,
  });

  final DistributionEntity distribution;
  final String farmerName;
  final DateFormat dateFormat;
  final Color statusColor;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(Icons.agriculture, color: statusColor),
        ),
        title: Text(
          farmerName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${distribution.seedType}  •  ${distribution.quantityDistributed} qty',
            ),
            Text(
              'Distributed: ${dateFormat.format(distribution.distributionDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Expected return: ${dateFormat.format(distribution.expectedYieldDueDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () {
          _showDetailSheet(context);
        },
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Distribution Details',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _detailRow('ID', distribution.id),
              _detailRow('Farmer', farmerName),
              _detailRow('Seed Type', distribution.seedType),
              _detailRow('Quantity', '${distribution.quantityDistributed}'),
              _detailRow('Distributed',
                  dateFormat.format(distribution.distributionDate)),
              _detailRow('Expected Return',
                  dateFormat.format(distribution.expectedYieldDueDate)),
              _detailRow('Status', statusLabel),
              _detailRow('Yield Returned', '${distribution.quantityReturned}'),
              _detailRow('Outstanding', '${distribution.outstandingQuantity}'),
              _detailRow('Recorded By', distribution.recordedByStaffId),
              if (distribution.amendmentReason != null)
                _detailRow('Amendment', distribution.amendmentReason!),
              if (distribution.amendedByAuthorityId != null)
                _detailRow('Amended By', distribution.amendedByAuthorityId!),
              const SizedBox(height: 24),
              Text(
                'Note: Distribution entries cannot be deleted. Only amendments with authority approval are permitted.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
