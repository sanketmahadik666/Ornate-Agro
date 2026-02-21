import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../shared/domain/entities/contact_log_entity.dart';
import '../../../farmers/presentation/bloc/farmer_bloc.dart';
import '../bloc/contact_log_bloc.dart';

class ContactLogPage extends StatefulWidget {
  const ContactLogPage({super.key, this.farmerId});

  final String? farmerId;

  @override
  State<ContactLogPage> createState() => _ContactLogPageState();
}

class _ContactLogPageState extends State<ContactLogPage> {
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  String? _selectedFarmerId;

  @override
  void initState() {
    super.initState();
    _selectedFarmerId = widget.farmerId;
    if (_selectedFarmerId != null) {
      context
          .read<ContactLogBloc>()
          .add(ContactLogLoadRequested(_selectedFarmerId!));
    }
  }

  void _showAddContactDialog() {
    if (_selectedFarmerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a farmer first')),
      );
      return;
    }

    final notesController = TextEditingController();
    String method = 'call';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Contact'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: method,
                decoration: const InputDecoration(labelText: 'Method'),
                items: const [
                  DropdownMenuItem(value: 'call', child: Text('Call')),
                  DropdownMenuItem(value: 'visit', child: Text('Visit')),
                  DropdownMenuItem(value: 'message', child: Text('Message')),
                ],
                onChanged: (v) => method = v!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
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
              final log = ContactLogEntity(
                id: const Uuid().v4(),
                farmerId: _selectedFarmerId!,
                contactDate: DateTime.now(),
                contactMethod: method,
                notes: notesController.text.trim(),
                recordedByStaffId: 'STAFF_001', // Ideally from Auth
              );
              context
                  .read<ContactLogBloc>()
                  .add(ContactLogCreateRequested(log));
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Log'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedFarmerId == null ? null : _showAddContactDialog,
        icon: const Icon(Icons.add_ic_call),
        label: const Text('Log Contact'),
      ),
      body: Column(
        children: [
          _buildFarmerSelector(),
          const Divider(height: 1),
          Expanded(child: _buildLogList()),
        ],
      ),
    );
  }

  Widget _buildFarmerSelector() {
    return BlocBuilder<FarmerBloc, FarmerState>(
      builder: (context, state) {
        if (state.farmers == null || state.farmers!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No farmers available'),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            value: _selectedFarmerId,
            decoration: const InputDecoration(
              labelText: 'Select Farmer',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            items: state.farmers!.map((f) {
              return DropdownMenuItem(
                value: f.id,
                child: Text('${f.fullName} (${f.village})'),
              );
            }).toList(),
            onChanged: (val) {
              setState(() => _selectedFarmerId = val);
              if (val != null) {
                context
                    .read<ContactLogBloc>()
                    .add(ContactLogLoadRequested(val));
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildLogList() {
    if (_selectedFarmerId == null) {
      return Center(
        child: Text(
          'Select a farmer to view contact logs',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      );
    }

    return BlocConsumer<ContactLogBloc, ContactLogState>(
      listener: (context, state) {
        if (state.status == ContactLogBlocStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage ?? 'Success')),
          );
        } else if (state.status == ContactLogBlocStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == ContactLogBlocStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = state.logs ?? [];
        if (logs.isEmpty) {
          return Center(
            child: Text(
              'No contact history',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            IconData icon;
            switch (log.contactMethod) {
              case 'call':
                icon = Icons.phone;
                break;
              case 'visit':
                icon = Icons.directions_walk;
                break;
              case 'message':
                icon = Icons.message;
                break;
              default:
                icon = Icons.contact_phone;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          log.contactMethod.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          _dateFormat.format(log.contactDate),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(log.notes),
                    const SizedBox(height: 8),
                    Text(
                      'Recorded by: ${log.recordedByStaffId}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
