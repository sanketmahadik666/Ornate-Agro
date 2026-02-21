import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../shared/domain/entities/farmer_entity.dart';
import '../bloc/farmer_bloc.dart';
import 'farmer_form_page.dart';

/// Req 2: Searchable/filterable list of farmers.
class FarmersListPage extends StatefulWidget {
  const FarmersListPage({super.key});

  @override
  State<FarmersListPage> createState() => _FarmersListPageState();
}

class _FarmersListPageState extends State<FarmersListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    setState(() => _searchQuery = value);
    if (value.isEmpty) {
      context.read<FarmerBloc>().add(const FarmerLoadRequested());
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<FarmerBloc>().add(FarmerSearchRequested(value));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmers'),
        actions: [
          BlocBuilder<FarmerBloc, FarmerState>(
            buildWhen: (prev, curr) =>
                prev.farmers?.length != curr.farmers?.length ||
                prev.status != curr.status,
            builder: (context, state) {
              final count = state.farmers?.length ?? 0;
              if (state.status != FarmerStatus.loaded || count == 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Text(
                    '$count',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => Navigator.pushNamed(context, AppRouter.farmersByCategory),
            tooltip: 'View by Category',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: BlocListener<FarmerBloc, FarmerState>(
              listenWhen: (prev, curr) => curr.status == FarmerStatus.success,
              listener: (context, state) {
                if (state.successMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.successMessage!),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  context.read<FarmerBloc>().add(const FarmerLoadRequested());
                }
              },
              child: BlocBuilder<FarmerBloc, FarmerState>(
                builder: (context, state) {
                  if (state.status == FarmerStatus.loading ||
                      state.status == FarmerStatus.success) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == FarmerStatus.failure) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text(
                            state.errorMessage ?? 'An error occurred',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.read<FarmerBloc>().add(const FarmerLoadRequested()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final farmers = state.farmers ?? [];

                  if (farmers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No farmers registered'
                                : 'No farmers found',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Tap + to add your first farmer'
                                : 'Try a different search term',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade500,
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                  onRefresh: () async {
                    context.read<FarmerBloc>().add(const FarmerLoadRequested());
                    await Future.delayed(const Duration(milliseconds: 400));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: farmers.length,
                    itemBuilder: (context, index) {
                      final farmer = farmers[index];
                      return _FarmerCard(
                        farmer: farmer,
                        onTap: () => _navigateToEdit(farmer),
                        onDelete: () => _showDeleteConfirmation(farmer),
                      );
                    },
                  ),
                );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAdd(),
        icon: const Icon(Icons.add),
        label: const Text('Add Farmer'),
      ),
    );
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
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name, contact, village, or ID...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    context.read<FarmerBloc>().add(const FarmerLoadRequested());
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  void _navigateToAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FarmerFormPage(),
      ),
    );
  }

  void _navigateToEdit(FarmerEntity farmer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FarmerFormPage(farmer: farmer),
      ),
    );
  }

  void _showDeleteConfirmation(FarmerEntity farmer) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Farmer?'),
        content: Text(
          'Are you sure you want to delete ${farmer.fullName}? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              HapticFeedback.mediumImpact();
              context.read<FarmerBloc>().add(FarmerDeleteRequested(farmer.id));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _FarmerCard extends StatelessWidget {
  const _FarmerCard({
    required this.farmer,
    required this.onTap,
    required this.onDelete,
  });

  final FarmerEntity farmer;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Color _getClassificationColor() {
    switch (farmer.classification) {
      case FarmerClassification.regular:
        return Colors.green;
      case FarmerClassification.sleepy:
        return Colors.orange;
      case FarmerClassification.blacklist:
        return Colors.red;
      case FarmerClassification.reminder:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getClassificationColor().withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: _getClassificationColor(),
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          farmer.id,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                                fontFamily: 'monospace',
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getClassificationColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      farmer.classification.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getClassificationColor(),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onDelete();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.delete_outline, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _InfoChip(icon: Icons.phone, label: farmer.contactNumber),
                  _InfoChip(icon: Icons.location_on, label: farmer.village),
                  _InfoChip(icon: Icons.agriculture, label: '${farmer.plotCount} plots'),
                  _InfoChip(icon: Icons.square_foot, label: '${farmer.areaPerPlot.toStringAsFixed(1)} acres/plot'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

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
