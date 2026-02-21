import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/domain/entities/crop_type_entity.dart';
import '../../../../core/utils/id_generator.dart';
import '../bloc/crop_type_bloc.dart';

/// Req 8: Crop types and growing period configuration (CRUD).
class CropConfigPage extends StatelessWidget {
  const CropConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CropTypeBloc, CropTypeState>(
      listener: (context, state) {
        if (state.status == CropTypeBlocStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage ?? 'Done')),
          );
        }
        if (state.status == CropTypeBlocStatus.failure) {
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
          appBar: AppBar(title: const Text('Crop Configuration')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCropDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Crop Type'),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CropTypeState state) {
    if (state.status == CropTypeBlocStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final cropTypes = state.cropTypes ?? [];

    if (cropTypes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grass_outlined,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No crop types configured',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Text('Tap + to add a crop type with its growing period',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: cropTypes.length,
      itemBuilder: (context, index) {
        final ct = cropTypes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.grass,
                  color: Theme.of(context).colorScheme.primary),
            ),
            title: Text(ct.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Growing period: ${ct.growingPeriodDays} days'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showCropDialog(context, existing: ct);
                } else if (value == 'delete') {
                  _confirmDelete(context, ct);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCropDialog(BuildContext context, {CropTypeEntity? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final daysController = TextEditingController(
        text: existing?.growingPeriodDays.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Crop Type' : 'Add Crop Type'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Crop Name',
                  hintText: 'e.g. Wheat, Rice, Soybean',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: daysController,
                decoration: const InputDecoration(
                  labelText: 'Growing Period (days)',
                  hintText: 'e.g. 120',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a valid number';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final cropType = CropTypeEntity(
                id: existing?.id ?? generateId(prefix: 'CRP'),
                name: nameController.text.trim(),
                growingPeriodDays: int.parse(daysController.text.trim()),
              );
              if (isEdit) {
                context
                    .read<CropTypeBloc>()
                    .add(CropTypeUpdateRequested(cropType));
              } else {
                context
                    .read<CropTypeBloc>()
                    .add(CropTypeCreateRequested(cropType));
              }
              Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, CropTypeEntity cropType) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Crop Type?'),
        content: Text(
            'Are you sure you want to delete "${cropType.name}"?\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context
                  .read<CropTypeBloc>()
                  .add(CropTypeDeleteRequested(cropType.id));
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
