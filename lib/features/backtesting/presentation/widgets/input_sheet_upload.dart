import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/services/file_parser_service.dart'
    show
        FileParserService,
        ValidationError,
        ValidationErrorType,
        FieldSchema,
        FieldType;

/// Input sheet upload component with validation (Req: Input Sheet Integration)
class InputSheetUpload extends StatefulWidget {
  const InputSheetUpload({
    super.key,
    this.onFileSelected,
    this.onTemplateSelected,
    this.onRemove,
    this.acceptedFormats = const ['.xlsx', '.xls', '.csv', '.json'],
    this.maxFileSizeMB = 10,
  });

  final ValueChanged<File>? onFileSelected;
  final ValueChanged<String>? onTemplateSelected; // Template ID
  final VoidCallback? onRemove;
  final List<String> acceptedFormats;
  final int maxFileSizeMB;

  @override
  State<InputSheetUpload> createState() => _InputSheetUploadState();
}

class _InputSheetUploadState extends State<InputSheetUpload> {
  File? _selectedFile;
  bool _isDragging = false;
  Map<String, dynamic>? _previewData;
  List<ValidationError> _validationErrors = [];
  bool _isValidating = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Input Configuration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_selectedFile == null) _buildUploadZone() else _buildFileInfo(),
            if (_previewData != null) ...[
              const SizedBox(height: 16),
              _buildPreview(),
            ],
            if (_validationErrors.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildValidationErrors(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadZone() {
    return Column(
      children: [
        InkWell(
          onTap: _pickFile,
          onTapDown: (_) => setState(() => _isDragging = true),
          onTapUp: (_) => setState(() => _isDragging = false),
          onTapCancel: () => setState(() => _isDragging = false),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _isDragging
                  ? Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3)
                  : Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: _isDragging
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Upload Input Sheet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Click to browse or drag and drop',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Supported: ${widget.acceptedFormats.join(', ')} (Max ${widget.maxFileSizeMB}MB)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('or'),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _showTemplateSelector,
              icon: const Icon(Icons.description_outlined),
              label: const Text('Use Template'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.insert_drive_file, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedFile!.path.split('/').last,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${(_selectedFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.preview),
              onPressed: _validateAndPreview,
              tooltip: 'Preview',
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadTemplate,
              tooltip: 'Download Template',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _removeFile,
              tooltip: 'Remove',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: true,
              onChanged: null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const Text('Validate before run'),
            const SizedBox(width: 16),
            Checkbox(
              value: true,
              onChanged: null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const Text('Override with UI form (if conflicts)'),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview() {
    if (_previewData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sheet Preview',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Parameter')),
                DataColumn(label: Text('Value')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Validation')),
              ],
              rows: _previewData!.entries.map((e) {
                final error = _validationErrors.firstWhere(
                  (err) => err.field == e.key,
                  orElse: () => ValidationError(
                      field: '', message: '', type: ValidationErrorType.none),
                );
                return DataRow(
                  cells: [
                    DataCell(Text(e.key)),
                    DataCell(Text(e.value.toString())),
                    DataCell(Text(_inferType(e.value))),
                    DataCell(
                      error.type == ValidationErrorType.none
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green, size: 16),
                                SizedBox(width: 4),
                                Text('Valid'),
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  error.type == ValidationErrorType.error
                                      ? Icons.error
                                      : Icons.warning,
                                  color: error.type == ValidationErrorType.error
                                      ? Colors.red
                                      : Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(error.message,
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationErrors() {
    final errors = _validationErrors
        .where((e) => e.type == ValidationErrorType.error)
        .toList();
    final warnings = _validationErrors
        .where((e) => e.type == ValidationErrorType.warning)
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: errors.isNotEmpty ? Colors.red.shade50 : Colors.orange.shade50,
        border: Border.all(
          color: errors.isNotEmpty ? Colors.red : Colors.orange,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                errors.isNotEmpty ? Icons.error : Icons.warning,
                color: errors.isNotEmpty ? Colors.red : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                '${errors.length} error(s), ${warnings.length} warning(s)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: errors.isNotEmpty
                      ? Colors.red.shade900
                      : Colors.orange.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...errors.map((e) => Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 4),
                child: Text('• ${e.field}: ${e.message}'),
              )),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...warnings.map((e) => Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 4),
                  child: Text('• ${e.field}: ${e.message}'),
                )),
          ],
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: errors.isEmpty ? null : _showFixSuggestions,
            child: const Text('Fix All'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions:
          widget.acceptedFormats.map((e) => e.replaceAll('.', '')).toList(),
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      if (file.lengthSync() > widget.maxFileSizeMB * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('File size exceeds ${widget.maxFileSizeMB}MB limit')),
          );
        }
        return;
      }
      setState(() {
        _selectedFile = file;
        _previewData = null;
        _validationErrors = [];
      });
      widget.onFileSelected?.call(file);
      _validateAndPreview();
    }
  }

  Future<void> _validateAndPreview() async {
    if (_selectedFile == null) return;
    setState(() {
      _isValidating = true;
      _previewData = null;
      _validationErrors = [];
    });

    try {
      // Parse file
      final parsedData = await FileParserService.parseFile(_selectedFile!);

      // Define schema for backtesting input
      final schema = <String, FieldSchema>{
        'start_date': FieldSchema(type: FieldType.date, required: true),
        'end_date': FieldSchema(type: FieldType.date, required: true),
        'capital': FieldSchema(type: FieldType.number, required: true, min: 0),
      };

      // Validate
      final errors = FileParserService.validateData(parsedData, schema);

      if (mounted) {
        setState(() {
          _previewData = parsedData;
          _validationErrors = errors;
          _isValidating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _validationErrors = [
            ValidationError(
              field: 'File',
              message: e.toString(),
              type: ValidationErrorType.error,
            ),
          ];
          _isValidating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing file: $e')),
        );
      }
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _previewData = null;
      _validationErrors = [];
    });
    widget.onRemove?.call();
  }

  void _showTemplateSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Template'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search templates...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _TemplateTile(
                      name: 'Momentum Basic',
                      description: 'Basic momentum strategy template',
                      onTap: () {
                        widget.onTemplateSelected?.call('momentum_basic');
                        Navigator.pop(context);
                      },
                    ),
                    _TemplateTile(
                      name: 'Mean Revert Basic',
                      description: 'Basic mean reversion strategy template',
                      onTap: () {
                        widget.onTemplateSelected?.call('mean_revert_basic');
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _downloadTemplate() {
    // TODO: Implement template download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template download not yet implemented')),
    );
  }

  void _showFixSuggestions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fix Suggestions'),
        content: const Text('Auto-fix functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _inferType(dynamic value) {
    if (value is int || value is double) return 'number';
    if (value is bool) return 'boolean';
    if (value is String) {
      if (RegExp(r'^\d{4}-\d{2}$').hasMatch(value)) return 'date';
      return 'string';
    }
    return 'unknown';
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.name,
    required this.description,
    required this.onTap,
  });

  final String name;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.description_outlined),
      title: Text(name),
      subtitle: Text(description),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
