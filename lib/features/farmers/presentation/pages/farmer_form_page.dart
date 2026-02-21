import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../shared/domain/entities/farmer_entity.dart';
import '../bloc/farmer_bloc.dart';

/// Add/Edit farmer form page
class FarmerFormPage extends StatefulWidget {
  const FarmerFormPage({this.farmer, super.key});

  final FarmerEntity? farmer;

  @override
  State<FarmerFormPage> createState() => _FarmerFormPageState();
}

class _FarmerFormPageState extends State<FarmerFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _contactController;
  late final TextEditingController _villageController;
  late final TextEditingController _plotCountController;
  late final TextEditingController _areaPerPlotController;
  late final TextEditingController _cropTypeController;
  
  FarmerClassification _selectedClassification = FarmerClassification.regular;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final farmer = widget.farmer;
    _fullNameController = TextEditingController(text: farmer?.fullName ?? '');
    _contactController = TextEditingController(text: farmer?.contactNumber ?? '');
    _villageController = TextEditingController(text: farmer?.village ?? '');
    _plotCountController = TextEditingController(text: farmer?.plotCount.toString() ?? '');
    _areaPerPlotController = TextEditingController(text: farmer?.areaPerPlot.toString() ?? '');
    _cropTypeController = TextEditingController(text: farmer?.assignedCropTypeId ?? '');
    _selectedClassification = farmer?.classification ?? FarmerClassification.regular;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactController.dispose();
    _villageController.dispose();
    _plotCountController.dispose();
    _areaPerPlotController.dispose();
    _cropTypeController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final farmer = FarmerEntity(
      id: widget.farmer?.id ?? generateFarmerId(),
      fullName: _fullNameController.text.trim(),
      contactNumber: _contactController.text.trim(),
      village: _villageController.text.trim(),
      plotCount: int.parse(_plotCountController.text),
      areaPerPlot: double.parse(_areaPerPlotController.text),
      assignedCropTypeId: _cropTypeController.text.trim(),
      classification: _selectedClassification,
      lastContactAt: widget.farmer?.lastContactAt,
      createdAt: widget.farmer?.createdAt,
      updatedAt: widget.farmer != null ? DateTime.now() : null,
    );

    if (widget.farmer == null) {
      context.read<FarmerBloc>().add(FarmerCreateRequested(farmer));
    } else {
      context.read<FarmerBloc>().add(FarmerUpdateRequested(farmer));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.farmer == null ? 'Add Farmer' : 'Edit Farmer'),
      ),
      body: BlocListener<FarmerBloc, FarmerState>(
        listener: (context, state) {
          if (state.status == FarmerStatus.success) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage ?? 'Success'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state.status == FarmerStatus.failure) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'An error occurred'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number *',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Contact number is required';
                    }
                    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                    if (digitsOnly.length < 10 || digitsOnly.length > 12) {
                      return 'Enter a valid 10-12 digit contact number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _villageController,
                  decoration: const InputDecoration(
                    labelText: 'Village/Location *',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Village is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _plotCountController,
                        decoration: const InputDecoration(
                          labelText: 'Number of Plots *',
                          prefixIcon: Icon(Icons.agriculture),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Plot count is required';
                          }
                          final count = int.tryParse(value);
                          if (count == null || count <= 0) {
                            return 'Enter a valid positive number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _areaPerPlotController,
                        decoration: const InputDecoration(
                          labelText: 'Area per Plot (acres) *',
                          prefixIcon: Icon(Icons.square_foot),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Area is required';
                          }
                          final area = double.tryParse(value);
                          if (area == null || area <= 0) {
                            return 'Enter a valid positive number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cropTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Crop Type ID *',
                    prefixIcon: Icon(Icons.eco),
                    hintText: 'e.g., crop-1',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Crop type is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<FarmerClassification>(
                  value: _selectedClassification,
                  decoration: const InputDecoration(
                    labelText: 'Classification',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: FarmerClassification.values.map((classification) {
                    return DropdownMenuItem(
                      value: classification,
                      child: Text(classification.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedClassification = value);
                    }
                  },
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.farmer == null ? 'Create Farmer' : 'Update Farmer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
