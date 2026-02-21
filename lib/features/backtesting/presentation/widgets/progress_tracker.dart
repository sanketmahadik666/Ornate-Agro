import 'package:flutter/material.dart';
import '../../domain/entities/backtest_progress.dart';

/// Progress tracker with elapsed time, ETA, background time (Req: Progress Tracking)
class ProgressTracker extends StatelessWidget {
  const ProgressTracker({
    super.key,
    required this.progress,
    this.onPause,
    this.onResume,
    this.onStop,
    this.onViewDetails,
  });

  final BacktestProgress progress;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backtest Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (progress.progressPercentage != null) ...[
              _buildProgressBar(context),
              const SizedBox(height: 16),
            ],
            _buildTimeMetrics(context),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final percentage = progress.progressPercentage ?? 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${percentage.toStringAsFixed(1)}% Complete',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (progress.status == BacktestStatus.paused)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PAUSED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getStatusColor(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeMetrics(BuildContext context) {
    return Column(
      children: [
        _TimeMetricRow(
          label: 'Elapsed Time:',
          value: progress.formattedElapsedTime,
          isPrimary: true,
        ),
        const SizedBox(height: 8),
        if (progress.estimatedRemainingSeconds != null)
          _TimeMetricRow(
            label: 'Estimated Remaining:',
            value: progress.formattedETA,
            isPrimary: false,
          ),
        if (progress.estimatedCompletionTime != null) ...[
          const SizedBox(height: 4),
          _TimeMetricRow(
            label: 'ETA:',
            value: _formatDateTime(progress.estimatedCompletionTime!),
            isPrimary: false,
            icon: Icons.access_time,
          ),
        ],
        const Divider(height: 24),
        _TimeMetricRow(
          label: 'Background Time:',
          value: progress.formattedBackgroundTime,
          isPrimary: false,
          tooltip: 'Time elapsed while you were away from this tab',
        ),
        const SizedBox(height: 8),
        _TimeMetricRow(
          label: 'Active Processing:',
          value: progress.formattedActiveTime,
          isPrimary: false,
          tooltip: 'Time spent actively processing (excludes pauses)',
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.difference(now).inDays > 0) {
      return '${dt.month}/${dt.day}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        if (progress.status == BacktestStatus.running)
          ElevatedButton.icon(
            onPressed: onPause,
            icon: const Icon(Icons.pause),
            label: const Text('Pause'),
          )
        else if (progress.status == BacktestStatus.paused)
          ElevatedButton.icon(
            onPressed: onResume,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onStop,
          icon: const Icon(Icons.stop),
          label: const Text('Stop'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onViewDetails,
          icon: const Icon(Icons.analytics_outlined),
          label: const Text('View Details'),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (progress.status) {
      case BacktestStatus.running:
        return Theme.of(context).colorScheme.primary;
      case BacktestStatus.paused:
        return Colors.orange;
      case BacktestStatus.completed:
        return Colors.green;
      case BacktestStatus.error:
        return Colors.red;
      case BacktestStatus.stopped:
        return Colors.grey;
    }
  }
}

class _TimeMetricRow extends StatelessWidget {
  const _TimeMetricRow({
    required this.label,
    required this.value,
    this.isPrimary = false,
    this.icon,
    this.tooltip,
  });

  final String label;
  final String value;
  final bool isPrimary;
  final IconData? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget child = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: isPrimary ? 16 : 14,
                fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isPrimary ? 18 : 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );

    if (tooltip != null) {
      child = Tooltip(
        message: tooltip,
        child: child,
      );
    }

    return child;
  }
}
