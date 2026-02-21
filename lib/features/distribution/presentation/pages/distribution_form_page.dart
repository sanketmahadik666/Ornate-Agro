import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/domain/entities/distribution_entity.dart';
import '../../../../shared/domain/entities/farmer_entity.dart';
import '../../../../shared/domain/entities/crop_type_entity.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../features/farmers/presentation/bloc/farmer_bloc.dart';
import '../../../../features/crop_config/presentation/bloc/crop_type_bloc.dart';
import '../bloc/distribution_bloc.dart';

/// Req 3 + Req 8: Form to create a new seed distribution entry.
/// Uses crop type's configured growing period for expected return date.
class DistributionFormPage extends StatefulWidget {
  const DistributionFormPage({super.key});

  @override
  State<DistributionFormPage> createState() => _DistributionFormPageState();
}

class _DistributionFormPageState extends State<DistributionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _dateFormat = DateFormat('dd MMM yyyy');

  FarmerEntity? _selectedFarmer;
  CropTypeEntity? _selectedCropType;
  DateTime _distributionDate = DateTime.now();

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  DateTime? get _expectedReturnDate => _selectedCropType == null
      ? null
      : _distributionDate
          .add(Duration(days: _selectedCropType!.growingPeriodDays));

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _distributionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _distributionDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFarmer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a farmer')),
      );
      return;
    }
    if (_selectedCropType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crop type')),
      );
      return;
    }

    final distribution = DistributionEntity(
      id: generateId(prefix: 'DST'),
      farmerId: _selectedFarmer!.id,
      seedType: _selectedCropType!.name,
      quantityDistributed: double.parse(_quantityController.text.trim()),
      distributionDate: _distributionDate,
      expectedYieldDueDate: _expectedReturnDate!,
      recordedByStaffId: 'current_user', // TODO: wire real user from AuthBloc
    );

    context
        .read<DistributionBloc>()
        .add(DistributionCreateRequested(distribution));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FarmerBloc, FarmerState>(
      builder: (context, farmerState) {
        final farmers = farmerState.farmers ?? [];

        return BlocBuilder<CropTypeBloc, CropTypeState>(
          builder: (context, cropState) {
            final cropTypes = cropState.cropTypes ?? [];

            return Scaffold(
              appBar: AppBar(title: const Text('New Distribution')),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Farmer picker
                      Text('Farmer',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<FarmerEntity>(
                        value: _selectedFarmer,
                        hint: const Text('Select a farmer'),
                        isExpanded: true,
                        items: farmers
                            .map((f) => DropdownMenuItem(
                                  value: f,
                                  child: Text('${f.fullName} (${f.village})'),
                                ))
                            .toList(),
                        onChanged: (farmer) =>
                            setState(() => _selectedFarmer = farmer),
                        validator: (value) =>
                            value == null ? 'Farmer is required' : null,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Crop type picker (replaces free-text seed type)
                      Text('Crop / Seed Type',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<CropTypeEntity>(
                        value: _selectedCropType,
                        hint: const Text('Select crop type'),
                        isExpanded: true,
                        items: cropTypes
                            .map((ct) => DropdownMenuItem(
                                  value: ct,
                                  child: Text(
                                      '${ct.name} (${ct.growingPeriodDays} days)'),
                                ))
                            .toList(),
                        onChanged: (ct) =>
                            setState(() => _selectedCropType = ct),
                        validator: (value) =>
                            value == null ? 'Crop type is required' : null,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.grass),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          helperText: cropTypes.isEmpty
                              ? 'No crop types configured — add one in Crop Configuration first'
                              : null,
                          helperStyle: const TextStyle(color: Colors.orange),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Quantity
                      TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          hintText: 'e.g. 50',
                          prefixIcon: const Icon(Icons.scale),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Quantity is required';
                          }
                          final qty = double.tryParse(value.trim());
                          if (qty == null || qty <= 0) {
                            return 'Enter a valid positive number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Distribution date
                      Text('Distribution Date',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).colorScheme.outline),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: 12),
                              Text(_dateFormat.format(_distributionDate)),
                              const Spacer(),
                              const Icon(Icons.edit, size: 16),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Expected return date (auto-calculated from crop type)
                      if (_selectedCropType != null)
                        Card(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.3),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.event_available,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Expected Yield Return Date',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _dateFormat
                                            .format(_expectedReturnDate!),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      Text(
                                        '${_selectedCropType!.name} — ${_selectedCropType!.growingPeriodDays}-day growing period',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.save),
                          label: const Text('Record Distribution'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
