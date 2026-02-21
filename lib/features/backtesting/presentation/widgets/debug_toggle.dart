import 'package:flutter/material.dart';

/// Debug mode toggle component (Req: Debug Logs Integration)
class DebugToggle extends StatelessWidget {
  const DebugToggle({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        title: const Text('Enable Debug Logs'),
        subtitle: const Text('Show detailed execution information'),
        value: enabled,
        onChanged: onChanged,
        secondary: Icon(
          Icons.bug_report_outlined,
          color: enabled ? Colors.orange : Colors.grey,
        ),
      ),
    );
  }
}
