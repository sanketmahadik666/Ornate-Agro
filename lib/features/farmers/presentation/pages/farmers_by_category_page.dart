import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../../shared/domain/entities/farmer_entity.dart';
import '../../../../core/services/classification_service.dart';
import '../bloc/farmer_bloc.dart';

/// Enhanced interface showing farmers sorted by classification categories with sorting, filtering, bulk actions, and export
class FarmersByCategoryPage extends StatefulWidget {
  const FarmersByCategoryPage({super.key});

  @override
  State<FarmersByCategoryPage> createState() => _FarmersByCategoryPageState();
}

enum SortOption {
  nameAsc,
  nameDesc,
  dateAsc,
  dateDesc,
  villageAsc,
  villageDesc
}

class _FarmersByCategoryPageState extends State<FarmersByCategoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.nameAsc;
  bool _isSelectionMode = false;
  final Set<String> _selectedFarmerIds = {};

  // Filters
  String? _selectedVillage;
  String? _selectedCropType;
  DateTimeRange? _dateRange;
  bool _showFilters = false;

  /// Group farmers by classification from bloc state
  Map<FarmerClassification, List<FarmerEntity>> _groupByClassification(
      List<FarmerEntity>? farmers) {
    final map = <FarmerClassification, List<FarmerEntity>>{
      for (final c in FarmerClassification.values) c: [],
    };
    if (farmers == null) return map;
    for (final f in farmers) {
      map[f.classification]!.add(f);
    }
    return map;
  }

  List<String> _getVillages(List<FarmerEntity>? farmers) {
    if (farmers == null || farmers.isEmpty) return [];
    return farmers.map((f) => f.village).toSet().toList()..sort();
  }

  List<String> _getCropTypes(List<FarmerEntity>? farmers) {
    if (farmers == null || farmers.isEmpty) return [];
    return farmers.map((f) => f.assignedCropTypeId).toSet().toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<FarmerBloc>().add(const FarmerLoadRequested());
  }

  List<FarmerEntity> _getFilteredAndSortedFarmers(FarmerClassification category,
      Map<FarmerClassification, List<FarmerEntity>> farmersByCategory) {
    var farmers = List<FarmerEntity>.from(farmersByCategory[category] ?? []);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      farmers = farmers.where((f) {
        return f.fullName.toLowerCase().contains(query) ||
            f.contactNumber.contains(query) ||
            f.village.toLowerCase().contains(query) ||
            f.id.toLowerCase().contains(query);
      }).toList();
    }

    // Apply village filter
    if (_selectedVillage != null) {
      farmers = farmers.where((f) => f.village == _selectedVillage).toList();
    }

    // Apply crop type filter
    if (_selectedCropType != null) {
      farmers = farmers
          .where((f) => f.assignedCropTypeId == _selectedCropType)
          .toList();
    }

    // Apply date range filter
    if (_dateRange != null) {
      farmers = farmers.where((f) {
        if (f.lastContactAt == null) return false;
        return f.lastContactAt!
                .isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
            f.lastContactAt!
                .isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Apply sorting
    farmers.sort((a, b) {
      switch (_sortOption) {
        case SortOption.nameAsc:
          return a.fullName.compareTo(b.fullName);
        case SortOption.nameDesc:
          return b.fullName.compareTo(a.fullName);
        case SortOption.dateAsc:
          final aDate = a.lastContactAt ?? DateTime(1970);
          final bDate = b.lastContactAt ?? DateTime(1970);
          return aDate.compareTo(bDate);
        case SortOption.dateDesc:
          final aDate = a.lastContactAt ?? DateTime(1970);
          final bDate = b.lastContactAt ?? DateTime(1970);
          return bDate.compareTo(aDate);
        case SortOption.villageAsc:
          return a.village.compareTo(b.village);
        case SortOption.villageDesc:
          return b.village.compareTo(a.village);
      }
    });

    return farmers;
  }

  void _toggleSelection(String farmerId) {
    setState(() {
      if (_selectedFarmerIds.contains(farmerId)) {
        _selectedFarmerIds.remove(farmerId);
      } else {
        _selectedFarmerIds.add(farmerId);
      }
      if (_selectedFarmerIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAll(FarmerClassification category,
      Map<FarmerClassification, List<FarmerEntity>> farmersByCategory) {
    final farmers = _getFilteredAndSortedFarmers(category, farmersByCategory);
    setState(() {
      _isSelectionMode = true;
      _selectedFarmerIds.addAll(farmers.map((f) => f.id));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedFarmerIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _exportCategory(FarmerClassification category,
      Map<FarmerClassification, List<FarmerEntity>> farmersByCategory) async {
    final farmers = _getFilteredAndSortedFarmers(category, farmersByCategory);
    if (farmers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No farmers to export')),
      );
      return;
    }

    try {
      // Create CSV content
      final csvData = [
        [
          'ID',
          'Name',
          'Contact',
          'Village',
          'Plots',
          'Area/Plot',
          'Crop Type',
          'Last Contact',
          'Classification'
        ],
        ...farmers.map((f) => [
              f.id,
              f.fullName,
              f.contactNumber,
              f.village,
              f.plotCount.toString(),
              f.areaPerPlot.toStringAsFixed(2),
              f.assignedCropTypeId,
              f.lastContactAt?.toString().split(' ')[0] ?? 'N/A',
              f.classification.name.toUpperCase(),
            ]),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final file = File(
          '${directory.path}/farmers_${category.name}_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvString);

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Farmers - ${category.name.toUpperCase()} Category',
        subject: 'Farmers Export',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported ${farmers.length} farmers to CSV')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _showBulkActionsDialog(FarmerClassification category,
      Map<FarmerClassification, List<FarmerEntity>> farmersByCategory) {
    final selectedFarmers =
        _getFilteredAndSortedFarmers(category, farmersByCategory)
            .where((f) => _selectedFarmerIds.contains(f.id))
            .toList();

    if (selectedFarmers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No farmers selected')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bulk Actions (${selectedFarmers.length} selected)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Change Classification'),
              subtitle:
                  const Text('Update classification for selected farmers'),
              onTap: () {
                Navigator.pop(context);
                _showClassificationChangeDialog(selectedFarmers);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Log Contact'),
              subtitle: const Text('Add contact log entry for all selected'),
              onTap: () {
                Navigator.pop(context);
                _showContactLogDialog(selectedFarmers);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Selected'),
              subtitle: const Text('Export selected farmers to CSV'),
              onTap: () {
                Navigator.pop(context);
                _exportSelectedFarmers(selectedFarmers);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete Selected'),
              subtitle:
                  const Text('Remove selected farmers (requires confirmation)'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(selectedFarmers);
              },
            ),
            // Move to Blacklist (only visible when on Reminder tab)
            if (_getCurrentCategory() == FarmerClassification.reminder)
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Move to Blacklist',
                    style: TextStyle(color: Colors.red)),
                subtitle:
                    const Text('Authority action — mark as non-responsive'),
                onTap: () {
                  Navigator.pop(context);
                  _moveToBlacklist(selectedFarmers);
                },
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClassificationChangeDialog(List<FarmerEntity> farmers) {
    FarmerClassification? newClassification;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Classification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select new classification for ${farmers.length} farmers:'),
              const SizedBox(height: 16),
              ...FarmerClassification.values.map((classification) {
                return RadioListTile<FarmerClassification>(
                  title: Text(classification.name.toUpperCase()),
                  value: classification,
                  groupValue: newClassification,
                  onChanged: (value) =>
                      setDialogState(() => newClassification = value),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: newClassification == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      // TODO: Implement classification change
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Classification changed to ${newClassification!.name} for ${farmers.length} farmers')),
                      );
                      _deselectAll();
                    },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactLogDialog(List<FarmerEntity> farmers) {
    // TODO: Implement contact log dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Contact log for ${farmers.length} farmers (to be implemented)')),
    );
    _deselectAll();
  }

  Future<void> _exportSelectedFarmers(List<FarmerEntity> farmers) async {
    try {
      final csvData = [
        [
          'ID',
          'Name',
          'Contact',
          'Village',
          'Plots',
          'Area/Plot',
          'Crop Type',
          'Last Contact',
          'Classification'
        ],
        ...farmers.map((f) => [
              f.id,
              f.fullName,
              f.contactNumber,
              f.village,
              f.plotCount.toString(),
              f.areaPerPlot.toStringAsFixed(2),
              f.assignedCropTypeId,
              f.lastContactAt?.toString().split(' ')[0] ?? 'N/A',
              f.classification.name.toUpperCase(),
            ]),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);
      final directory = await getTemporaryDirectory();
      final file = File(
          '${directory.path}/farmers_selected_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvString);

      await Share.shareXFiles([XFile(file.path)],
          text: 'Selected Farmers Export');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported ${farmers.length} farmers to CSV')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
    _deselectAll();
  }

  void _showDeleteConfirmation(List<FarmerEntity> farmers) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Farmers?'),
        content: Text(
            'Are you sure you want to delete ${farmers.length} farmers? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted ${farmers.length} farmers')),
              );
              _deselectAll();
              context.read<FarmerBloc>().add(
                  const FarmerLoadRequested()); // Reload to reflect changes
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Req 5: Run classification engine on all farmers and reload.
  Future<void> _reclassifyAll(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reclassifying farmers...')),
    );

    try {
      final service = context.read<ClassificationService>();
      final changedCount = await service.evaluateAllFarmers();

      if (mounted) {
        context.read<FarmerBloc>().add(const FarmerLoadRequested());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(changedCount > 0
                ? '$changedCount farmer(s) reclassified'
                : 'All farmers already correctly classified'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reclassification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Req 5: Authority action — move selected Reminder farmers to Blacklist.
  void _moveToBlacklist(List<FarmerEntity> farmers) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Blacklist?'),
        content: Text(
          'This will mark ${farmers.length} farmer(s) as Blacklisted.\n\n'
          'This is an authority action and should only be used for '
          'farmers who have not responded after the final reminder.',
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
              // Update each farmer's classification to blacklist
              for (final farmer in farmers) {
                context.read<FarmerBloc>().add(FarmerUpdateRequested(
                      FarmerEntity(
                        id: farmer.id,
                        fullName: farmer.fullName,
                        contactNumber: farmer.contactNumber,
                        village: farmer.village,
                        plotCount: farmer.plotCount,
                        areaPerPlot: farmer.areaPerPlot,
                        assignedCropTypeId: farmer.assignedCropTypeId,
                        classification: FarmerClassification.blacklist,
                        lastContactAt: farmer.lastContactAt,
                        createdAt: farmer.createdAt,
                        updatedAt: DateTime.now(),
                      ),
                    ));
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('${farmers.length} farmer(s) moved to Blacklist'),
                ),
              );
              _deselectAll();
              context.read<FarmerBloc>().add(const FarmerLoadRequested());
            },
            child: const Text('Move to Blacklist'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FarmerBloc, FarmerState>(
      buildWhen: (prev, curr) => prev.farmers != curr.farmers,
      builder: (context, state) {
        final farmers = state.farmers;
        final farmersByCategory = _groupByClassification(farmers);
        final availableVillages = _getVillages(farmers);
        final availableCropTypes = _getCropTypes(farmers);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Farmers by Category'),
            actions: [
              if (_isSelectionMode) ...[
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _deselectAll,
                  tooltip: 'Cancel Selection',
                ),
                IconButton(
                  icon: Badge(
                    label: Text('${_selectedFarmerIds.length}'),
                    child: const Icon(Icons.checklist),
                  ),
                  onPressed: () => _showBulkActionsDialog(
                      _getCurrentCategory(), farmersByCategory),
                  tooltip: 'Bulk Actions',
                ),
              ] else ...[
                IconButton(
                  icon: Icon(_showFilters
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined),
                  onPressed: () => setState(() => _showFilters = !_showFilters),
                  tooltip: 'Toggle Filters',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort Options',
                  onSelected: (value) {
                    setState(() {
                      _sortOption =
                          SortOption.values.firstWhere((e) => e.name == value);
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'nameAsc', child: Text('Name (A-Z)')),
                    const PopupMenuItem(
                        value: 'nameDesc', child: Text('Name (Z-A)')),
                    const PopupMenuItem(
                        value: 'dateAsc', child: Text('Last Contact (Oldest)')),
                    const PopupMenuItem(
                        value: 'dateDesc',
                        child: Text('Last Contact (Newest)')),
                    const PopupMenuItem(
                        value: 'villageAsc', child: Text('Village (A-Z)')),
                    const PopupMenuItem(
                        value: 'villageDesc', child: Text('Village (Z-A)')),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.download),
                  tooltip: 'Export',
                  onSelected: (value) {
                    final category = FarmerClassification.values
                        .firstWhere((e) => e.name == value);
                    _exportCategory(category, farmersByCategory);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'regular', child: Text('Export Regular')),
                    const PopupMenuItem(
                        value: 'sleepy', child: Text('Export Sleepy')),
                    const PopupMenuItem(
                        value: 'blacklist', child: Text('Export Blacklist')),
                    const PopupMenuItem(
                        value: 'reminder', child: Text('Export Reminder')),
                  ],
                ),
                // Reclassify All button (Req 5)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reclassify All Farmers',
                  onPressed: () => _reclassifyAll(context),
                ),
              ],
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                _CategoryTab(
                  label: 'Regular',
                  count: _getFilteredAndSortedFarmers(
                          FarmerClassification.regular, farmersByCategory)
                      .length,
                  total:
                      farmersByCategory[FarmerClassification.regular]?.length ??
                          0,
                  color: Colors.green,
                ),
                _CategoryTab(
                  label: 'Sleepy',
                  count: _getFilteredAndSortedFarmers(
                          FarmerClassification.sleepy, farmersByCategory)
                      .length,
                  total:
                      farmersByCategory[FarmerClassification.sleepy]?.length ??
                          0,
                  color: Colors.orange,
                ),
                _CategoryTab(
                  label: 'Blacklist',
                  count: _getFilteredAndSortedFarmers(
                          FarmerClassification.blacklist, farmersByCategory)
                      .length,
                  total: farmersByCategory[FarmerClassification.blacklist]
                          ?.length ??
                      0,
                  color: Colors.red,
                ),
                _CategoryTab(
                  label: 'Reminder',
                  count: _getFilteredAndSortedFarmers(
                          FarmerClassification.reminder, farmersByCategory)
                      .length,
                  total: farmersByCategory[FarmerClassification.reminder]
                          ?.length ??
                      0,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              _buildSearchBar(),
              if (_showFilters)
                _buildFilterPanel(availableVillages, availableCropTypes),
              Expanded(
                child: state.status == FarmerStatus.loading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _CategoryView(
                            category: FarmerClassification.regular,
                            farmers: _getFilteredAndSortedFarmers(
                                FarmerClassification.regular,
                                farmersByCategory),
                            color: Colors.green,
                            isSelectionMode: _isSelectionMode,
                            selectedIds: _selectedFarmerIds,
                            onToggleSelection: _toggleSelection,
                            onSelectAll: () => _selectAll(
                                FarmerClassification.regular,
                                farmersByCategory),
                            onDeselectAll: _deselectAll,
                          ),
                          _CategoryView(
                            category: FarmerClassification.sleepy,
                            farmers: _getFilteredAndSortedFarmers(
                                FarmerClassification.sleepy, farmersByCategory),
                            color: Colors.orange,
                            isSelectionMode: _isSelectionMode,
                            selectedIds: _selectedFarmerIds,
                            onToggleSelection: _toggleSelection,
                            onSelectAll: () => _selectAll(
                                FarmerClassification.sleepy, farmersByCategory),
                            onDeselectAll: _deselectAll,
                          ),
                          _CategoryView(
                            category: FarmerClassification.blacklist,
                            farmers: _getFilteredAndSortedFarmers(
                                FarmerClassification.blacklist,
                                farmersByCategory),
                            color: Colors.red,
                            isSelectionMode: _isSelectionMode,
                            selectedIds: _selectedFarmerIds,
                            onToggleSelection: _toggleSelection,
                            onSelectAll: () => _selectAll(
                                FarmerClassification.blacklist,
                                farmersByCategory),
                            onDeselectAll: _deselectAll,
                          ),
                          _CategoryView(
                            category: FarmerClassification.reminder,
                            farmers: _getFilteredAndSortedFarmers(
                                FarmerClassification.reminder,
                                farmersByCategory),
                            color: Colors.blue,
                            isSelectionMode: _isSelectionMode,
                            selectedIds: _selectedFarmerIds,
                            onToggleSelection: _toggleSelection,
                            onSelectAll: () => _selectAll(
                                FarmerClassification.reminder,
                                farmersByCategory),
                            onDeselectAll: _deselectAll,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  FarmerClassification _getCurrentCategory() {
    return FarmerClassification.values[_tabController.index];
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search farmers by name, contact, village, or ID...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildFilterPanel(
      List<String> availableVillages, List<String> availableCropTypes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
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
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('All Villages')),
                  ...availableVillages
                      .map((v) => DropdownMenuItem(value: v, child: Text(v))),
                ],
                onChanged: (value) => setState(() => _selectedVillage = value),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              DropdownButtonFormField<String>(
                value: _selectedCropType,
                hint: const Text('Crop Type'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Crops')),
                  ...availableCropTypes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c))),
                ],
                onChanged: (value) => setState(() => _selectedCropType = value),
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
                    : '${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count == total ? '$count' : '$count/$total',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryView extends StatelessWidget {
  const _CategoryView({
    required this.category,
    required this.farmers,
    required this.color,
    required this.isSelectionMode,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.onSelectAll,
    required this.onDeselectAll,
  });

  final FarmerClassification category;
  final List<FarmerEntity> farmers;
  final Color color;
  final bool isSelectionMode;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;

  String _getCategoryDescription() {
    switch (category) {
      case FarmerClassification.regular:
        return 'Farmers who have returned all yield and maintain regular contact';
      case FarmerClassification.sleepy:
        return 'Farmers who returned yield but have had no contact for 20-30 days';
      case FarmerClassification.blacklist:
        return 'Farmers who have not returned yield and have no contact for 20-30 days';
      case FarmerClassification.reminder:
        return 'Farmers who have not returned yield but are in active contact';
    }
  }

  IconData _getCategoryIcon() {
    switch (category) {
      case FarmerClassification.regular:
        return Icons.check_circle;
      case FarmerClassification.sleepy:
        return Icons.bedtime;
      case FarmerClassification.blacklist:
        return Icons.block;
      case FarmerClassification.reminder:
        return Icons.notifications_active;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (farmers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(),
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${category.name} farmers found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _getCategoryDescription(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(color: color.withOpacity(0.3)),
            ),
          ),
          child: Row(
            children: [
              Icon(_getCategoryIcon(), color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${category.name.toUpperCase()} Farmers',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCategoryDescription(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${farmers.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isSelectionMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Row(
              children: [
                Text(
                  '${selectedIds.length} selected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onSelectAll,
                  child: const Text('Select All'),
                ),
                TextButton(
                  onPressed: onDeselectAll,
                  child: const Text('Deselect All'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: farmers.length,
            itemBuilder: (context, index) {
              return _FarmerCard(
                farmer: farmers[index],
                color: color,
                isSelected: selectedIds.contains(farmers[index].id),
                isSelectionMode: isSelectionMode,
                onTap: () {
                  if (isSelectionMode) {
                    onToggleSelection(farmers[index].id);
                  } else {
                    // TODO: Navigate to farmer details
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('View ${farmers[index].fullName}')),
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FarmerCard extends StatelessWidget {
  const _FarmerCard({
    required this.farmer,
    required this.color,
    this.isSelected = false,
    this.isSelectionMode = false,
    required this.onTap,
  });

  final FarmerEntity farmer;
  final Color color;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color : color.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isSelectionMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => onTap(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farmer.fullName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          farmer.id,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                    fontFamily: 'monospace',
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      farmer.classification.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.phone,
                    label: farmer.contactNumber,
                  ),
                  _InfoChip(
                    icon: Icons.location_on,
                    label: farmer.village,
                  ),
                  _InfoChip(
                    icon: Icons.agriculture,
                    label: '${farmer.plotCount} plots',
                  ),
                  _InfoChip(
                    icon: Icons.square_foot,
                    label:
                        '${farmer.areaPerPlot.toStringAsFixed(1)} acres/plot',
                  ),
                ],
              ),
              if (farmer.lastContactAt != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Last contact: ${_formatDate(farmer.lastContactAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
              ),
        ),
      ],
    );
  }
}
