import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/domain/entities/farmer_entity.dart';
import '../../../../shared/domain/entities/distribution_entity.dart';
import '../../../farmers/presentation/bloc/farmer_bloc.dart';
import '../../../distribution/presentation/bloc/distribution_bloc.dart';
import '../../domain/services/report_export_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _exportService = ReportExportService();
  final _dateFormat = DateFormat('dd MMM yyyy');

  // Filters for General Tab
  String? _selectedVillage;
  String? _selectedCropType;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Blacklist'),
            Tab(text: 'Reminder'),
          ],
        ),
      ),
      body: BlocBuilder<FarmerBloc, FarmerState>(
        builder: (context, farmerState) {
          return BlocBuilder<DistributionBloc, DistributionState>(
            builder: (context, distState) {
              if (farmerState.status == FarmerStatus.loading ||
                  distState.status == DistributionBlocStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              final farmers = farmerState.farmers ?? [];
              final distributions = distState.distributions ?? [];

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildGeneralTab(farmers, distributions),
                  _buildBlacklistTab(farmers, distributions),
                  _buildReminderTab(farmers, distributions),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleExport(context),
        icon: const Icon(Icons.download),
        label: const Text('Export'),
      ),
    );
  }

  Widget _buildGeneralTab(
      List<FarmerEntity> farmers, List<DistributionEntity> distributions) {
    // Apply filters
    var filteredFarmers = farmers.toList();
    if (_selectedVillage != null) {
      filteredFarmers =
          filteredFarmers.where((f) => f.village == _selectedVillage).toList();
    }
    if (_selectedCropType != null) {
      filteredFarmers = filteredFarmers
          .where((f) => f.assignedCropTypeId == _selectedCropType)
          .toList();
    }
    if (_dateRange != null) {
      filteredFarmers = filteredFarmers.where((f) {
        if (f.createdAt == null) return false;
        return f.createdAt!.isAfter(_dateRange!.start) &&
            f.createdAt!.isBefore(_dateRange!.end);
      }).toList();
    }

    // Get filter options
    final villages = farmers.map((f) => f.village).toSet().toList()..sort();
    final cropTypes = farmers.map((f) => f.assignedCropTypeId).toSet().toList()
      ..sort();

    return Column(
      children: [
        _buildFilterPanel(villages, cropTypes),
        const Divider(height: 1),
        Expanded(
          child: filteredFarmers.isEmpty
              ? const Center(child: Text('No data matching filters'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredFarmers.length,
                  itemBuilder: (context, index) {
                    final f = filteredFarmers[index];
                    final fDistributions =
                        distributions.where((d) => d.farmerId == f.id).toList();
                    double outstanding = 0;
                    for (var d in fDistributions) {
                      outstanding += d.outstandingQuantity;
                    }

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(f.fullName.substring(0, 1)),
                        ),
                        title: Text(f.fullName),
                        subtitle: Text(
                            'Village: ${f.village} • Crop: ${f.assignedCropTypeId}\nOutstanding Yield: $outstanding'),
                        trailing: Text(f.classification.name.toUpperCase()),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterPanel(List<String> villages, List<String> cropTypes) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, size: 20),
              const SizedBox(width: 8),
              const Text('General Filters'),
              const Spacer(),
              if (_selectedVillage != null ||
                  _selectedCropType != null ||
                  _dateRange != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedVillage = null;
                      _selectedCropType = null;
                      _dateRange = null;
                    });
                  },
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedVillage,
                hint: const Text('Village'),
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: villages
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedVillage = val),
              ),
              DropdownButtonFormField<String>(
                value: _selectedCropType,
                hint: const Text('Crop Type'),
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: cropTypes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCropType = val),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBlacklistTab(
      List<FarmerEntity> farmers, List<DistributionEntity> distributions) {
    final blacklistFarmers = farmers
        .where((f) => f.classification == FarmerClassification.blacklist)
        .toList();

    if (blacklistFarmers.isEmpty) {
      return const Center(child: Text('No blacklisted farmers.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: blacklistFarmers.length,
      itemBuilder: (context, index) {
        final f = blacklistFarmers[index];
        final fDistributions =
            distributions.where((d) => d.farmerId == f.id).toList();
        double outstanding = 0;
        for (var d in fDistributions) {
          outstanding += d.outstandingQuantity;
        }

        return Card(
          color: Colors.red.withOpacity(0.05),
          child: ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: Text(f.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Outstanding Yield: $outstanding'),
                Text(
                    'Last Contact: ${f.lastContactAt != null ? _dateFormat.format(f.lastContactAt!) : 'Never'}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReminderTab(
      List<FarmerEntity> farmers, List<DistributionEntity> distributions) {
    final reminderFarmers = farmers
        .where((f) => f.classification == FarmerClassification.reminder)
        .toList();

    // Sort by urgency (older contact date = more urgent)
    reminderFarmers.sort((a, b) {
      if (a.lastContactAt == null && b.lastContactAt == null) return 0;
      if (a.lastContactAt == null) return -1;
      if (b.lastContactAt == null) return 1;
      return a.lastContactAt!.compareTo(b.lastContactAt!);
    });

    if (reminderFarmers.isEmpty) {
      return const Center(child: Text('No reminder farmers.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reminderFarmers.length,
      itemBuilder: (context, index) {
        final f = reminderFarmers[index];
        final fDistributions =
            distributions.where((d) => d.farmerId == f.id).toList();
        double outstanding = 0;
        for (var d in fDistributions) {
          outstanding += d.outstandingQuantity;
        }

        return Card(
          color: Colors.blue.withOpacity(0.05),
          child: ListTile(
            leading: const Icon(Icons.notifications_active, color: Colors.blue),
            title: Text(f.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Outstanding Yield: $outstanding'),
                Text(
                    'Last Contact: ${f.lastContactAt != null ? _dateFormat.format(f.lastContactAt!) : 'Never'}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    final farmers = context.read<FarmerBloc>().state.farmers ?? [];
    final distributions =
        context.read<DistributionBloc>().state.distributions ?? [];

    // Determine which tab is currently active to build data correctly
    final currentIndex = _tabController.index;

    List<List<String>> data = [];
    String title = '';

    if (currentIndex == 0) {
      title = 'General Farmer Report';
      data.add([
        'ID',
        'Name',
        'Contact',
        'Village',
        'Classification',
        'Total Outstanding Yield',
      ]);

      var filteredFarmers = farmers;
      if (_selectedVillage != null) {
        filteredFarmers = filteredFarmers
            .where((f) => f.village == _selectedVillage)
            .toList();
      }
      if (_selectedCropType != null) {
        filteredFarmers = filteredFarmers
            .where((f) => f.assignedCropTypeId == _selectedCropType)
            .toList();
      }

      for (var f in filteredFarmers) {
        final fDist = distributions.where((d) => d.farmerId == f.id);
        final outstanding =
            fDist.fold(0.0, (sum, d) => sum + d.outstandingQuantity);

        data.add([
          f.id,
          f.fullName,
          f.contactNumber,
          f.village,
          f.classification.name,
          outstanding.toStringAsFixed(2),
        ]);
      }
    } else if (currentIndex == 1) {
      title = 'Blacklist Report';
      data.add([
        'Name',
        'Contact',
        'Village',
        'Last Known Contact Date',
        'Total Outstanding Yield',
      ]);

      final blacklist = farmers
          .where((f) => f.classification == FarmerClassification.blacklist);
      for (var f in blacklist) {
        final fDist = distributions.where((d) => d.farmerId == f.id);
        final outstanding =
            fDist.fold(0.0, (sum, d) => sum + d.outstandingQuantity);
        data.add([
          f.fullName,
          f.contactNumber,
          f.village,
          f.lastContactAt != null
              ? _dateFormat.format(f.lastContactAt!)
              : 'N/A',
          outstanding.toStringAsFixed(2),
        ]);
      }
    } else if (currentIndex == 2) {
      title = 'Reminder Urgent Report';
      data.add([
        'Name',
        'Contact',
        'Village',
        'Last Contact Date',
        'Total Outstanding Yield',
      ]);

      final reminder = farmers
          .where((f) => f.classification == FarmerClassification.reminder)
          .toList();
      reminder.sort((a, b) {
        if (a.lastContactAt == null && b.lastContactAt == null) return 0;
        if (a.lastContactAt == null) return -1;
        if (b.lastContactAt == null) return 1;
        return a.lastContactAt!.compareTo(b.lastContactAt!);
      });

      for (var f in reminder) {
        final fDist = distributions.where((d) => d.farmerId == f.id);
        final outstanding =
            fDist.fold(0.0, (sum, d) => sum + d.outstandingQuantity);
        data.add([
          f.fullName,
          f.contactNumber,
          f.village,
          f.lastContactAt != null
              ? _dateFormat.format(f.lastContactAt!)
              : 'N/A',
          outstanding.toStringAsFixed(2),
        ]);
      }
    }

    if (data.length <= 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export')),
        );
      }
      return;
    }

    // Modal to choose CSV vs PDF
    showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.table_view),
                  title: const Text('Export as CSV'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _exportService.exportToCsv(title: title, data: data);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text('Export as PDF'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _exportService.exportToPdf(title: title, data: data);
                  },
                ),
              ],
            ),
          );
        });
  }
}
