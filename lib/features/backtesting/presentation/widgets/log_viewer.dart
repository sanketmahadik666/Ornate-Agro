import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/log_entry.dart';

/// Live log streaming viewer with categorization (Req: Log Categorization, Live Streaming)
class LogViewer extends StatefulWidget {
  const LogViewer({
    super.key,
    required this.logs,
    this.autoScroll = true,
    this.showDebug = false,
    this.onFilterChange,
    this.onClear,
    this.onExport,
  });

  final List<LogEntry> logs;
  final bool autoScroll;
  final bool showDebug;
  final ValueChanged<Set<LogCategory>>? onFilterChange;
  final VoidCallback? onClear;
  final ValueChanged<String>? onExport; // 'csv' | 'json' | 'txt'

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  final ScrollController _scrollController = ScrollController();
  final Set<LogCategory> _activeFilters = {LogCategory.informational, LogCategory.warning, LogCategory.error};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.showDebug) {
      _activeFilters.add(LogCategory.debug);
    }
  }

  @override
  void didUpdateWidget(LogViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoScroll && widget.logs.length > oldWidget.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  List<LogEntry> get _filteredLogs {
    return widget.logs.where((log) {
      if (!_activeFilters.contains(log.category)) return false;
      if (!widget.showDebug && log.isDebug) return false;
      if (_searchQuery.isNotEmpty && !log.message.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLogs;
    return Column(
      children: [
        _buildHeader(filtered.length),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _LogEntryWidget(log: filtered[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(int filteredCount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildLiveIndicator(),
              const SizedBox(width: 16),
              Text('Logs: ${filteredCount} of ${widget.logs.length}'),
              const Spacer(),
              _buildFilterToggles(),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.search, size: 20),
                onPressed: () => _showSearchDialog(),
                tooltip: 'Search logs',
              ),
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: widget.onClear,
                tooltip: 'Clear logs',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.download, size: 20),
                onSelected: widget.onExport,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
                  const PopupMenuItem(value: 'json', child: Text('Export as JSON')),
                  const PopupMenuItem(value: 'txt', child: Text('Export as TXT')),
                ],
              ),
            ],
          ),
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Chip(
                    label: Text('Search: "$_searchQuery"'),
                    onDeleted: () => setState(() => _searchQuery = ''),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        const Text('Live', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildFilterToggles() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FilterChip(
          label: 'Info',
          category: LogCategory.informational,
          selected: _activeFilters.contains(LogCategory.informational),
          onTap: () => _toggleFilter(LogCategory.informational),
        ),
        const SizedBox(width: 4),
        _FilterChip(
          label: 'Warning',
          category: LogCategory.warning,
          selected: _activeFilters.contains(LogCategory.warning),
          onTap: () => _toggleFilter(LogCategory.warning),
        ),
        const SizedBox(width: 4),
        _FilterChip(
          label: 'Error',
          category: LogCategory.error,
          selected: _activeFilters.contains(LogCategory.error),
          onTap: () => _toggleFilter(LogCategory.error),
        ),
        if (widget.showDebug) ...[
          const SizedBox(width: 4),
          _FilterChip(
            label: 'Debug',
            category: LogCategory.debug,
            selected: _activeFilters.contains(LogCategory.debug),
            onTap: () => _toggleFilter(LogCategory.debug),
          ),
        ],
      ],
    );
  }

  void _toggleFilter(LogCategory category) {
    setState(() {
      if (_activeFilters.contains(category)) {
        _activeFilters.remove(category);
      } else {
        _activeFilters.add(category);
      }
    });
    widget.onFilterChange?.call(_activeFilters);
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Logs'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter search query...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text(
            'No logs to display',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
          ),
          if (_activeFilters.isEmpty || _searchQuery.isNotEmpty)
            Text(
              'Try adjusting filters or search',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final LogCategory category;
  final bool selected;
  final VoidCallback onTap;

  Color _getColor(BuildContext context) {
    switch (category) {
      case LogCategory.informational:
        return const Color(0xFF2196F3);
      case LogCategory.warning:
        return const Color(0xFFFF9800);
      case LogCategory.error:
        return const Color(0xFFD32F2F);
      case LogCategory.debug:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      side: BorderSide(color: selected ? color : Colors.grey.shade400),
      labelStyle: TextStyle(color: selected ? color : Colors.grey.shade700),
    );
  }
}

class _LogEntryWidget extends StatefulWidget {
  const _LogEntryWidget({required this.log});

  final LogEntry log;

  @override
  State<_LogEntryWidget> createState() => _LogEntryWidgetState();
}

class _LogEntryWidgetState extends State<_LogEntryWidget> {
  bool _expanded = false;

  Color _getBackgroundColor() {
    switch (widget.log.category) {
      case LogCategory.informational:
        return const Color(0xFFE3F2FD);
      case LogCategory.warning:
        return const Color(0xFFFFF8E1);
      case LogCategory.error:
        return const Color(0xFFFFEBEE);
      case LogCategory.debug:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _getBorderColor() {
    switch (widget.log.category) {
      case LogCategory.informational:
        return const Color(0xFF2196F3);
      case LogCategory.warning:
        return const Color(0xFFFFC107);
      case LogCategory.error:
        return const Color(0xFFF44336);
      case LogCategory.debug:
        return const Color(0xFFCCCCCC);
    }
  }

  IconData _getIcon() {
    switch (widget.log.category) {
      case LogCategory.informational:
        return Icons.info_outline;
      case LogCategory.warning:
        return Icons.warning_amber_outlined;
      case LogCategory.error:
        return Icons.error_outline;
      case LogCategory.debug:
        return Icons.bug_report_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor();
    final borderColor = _getBorderColor();
    final icon = _getIcon();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: borderColor),
                  const SizedBox(width: 8),
                  Text(
                    widget.log.formattedTimestamp,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.log.category.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.log.message));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Log copied to clipboard')),
                      );
                    },
                    tooltip: 'Copy log',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (widget.log.details != null || widget.log.metadata != null)
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 0, 12, 12),
            child: Text(
              widget.log.message,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
          if (_expanded && (widget.log.details != null || widget.log.metadata != null))
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.log.details != null) ...[
                    const Text('Details:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      widget.log.details!,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                  if (widget.log.metadata != null) ...[
                    if (widget.log.details != null) const SizedBox(height: 12),
                    const Text('Metadata:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    ...widget.log.metadata!.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '${e.key}: ${e.value}',
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          ),
                        )),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
