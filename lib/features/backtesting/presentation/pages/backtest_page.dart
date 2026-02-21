import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/debug_toggle.dart';
import '../widgets/input_sheet_upload.dart';
import '../widgets/log_viewer.dart';
import '../widgets/progress_tracker.dart';
import '../../domain/entities/log_entry.dart';
import '../../domain/entities/backtest_progress.dart';

/// Main backtesting page integrating all components
class BacktestPage extends StatefulWidget {
  const BacktestPage({super.key});

  @override
  State<BacktestPage> createState() => _BacktestPageState();
}

class _BacktestPageState extends State<BacktestPage> {
  bool _debugEnabled = false;
  List<LogEntry> _logs = [];
  BacktestProgress _progress =
      const BacktestProgress(status: BacktestStatus.stopped);
  File? _inputFile;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _simulateLogs();
  }

  void _simulateLogs() {
    // Simulate some initial logs
    _logs = [
      LogEntry(
        id: '1',
        timestamp: DateTime.now().subtract(const Duration(seconds: 5)),
        category: LogCategory.informational,
        message: 'Backtest initialized',
      ),
      LogEntry(
        id: '2',
        timestamp: DateTime.now().subtract(const Duration(seconds: 4)),
        category: LogCategory.informational,
        message: 'Loading input configuration...',
      ),
    ];
  }

  void _startBacktest() {
    if (_inputFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an input sheet first')),
      );
      return;
    }

    setState(() {
      _isRunning = true;
      _progress = BacktestProgress(
        status: BacktestStatus.running,
        progressPercentage: 0,
        elapsedSeconds: 0,
        startTime: DateTime.now(),
      );
    });

    _simulateProgress();
    _simulateLiveLogs();
  }

  void _simulateProgress() {
    // Simulate progress updates
    int elapsed = 0;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isRunning) {
        timer.cancel();
        return;
      }

      elapsed++;
      final progress = (elapsed / 120 * 100).clamp(0, 100).toDouble();
      final remaining = ((120 - elapsed) * 1000).round();

      setState(() {
        _progress = BacktestProgress(
          status: BacktestStatus.running,
          progressPercentage: progress,
          elapsedSeconds: elapsed,
          backgroundSeconds: 0, // TODO: Track background time
          activeSeconds: elapsed,
          estimatedRemainingSeconds: remaining,
          startTime: _progress.startTime,
        );
      });

      if (progress >= 100) {
        timer.cancel();
        setState(() {
          _isRunning = false;
          _progress = BacktestProgress(
            status: BacktestStatus.completed,
            progressPercentage: 100,
            elapsedSeconds: elapsed,
          );
        });
      }
    });
  }

  void _simulateLiveLogs() {
    // Simulate live log generation
    int logId = _logs.length + 1;
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || !_isRunning) {
        timer.cancel();
        return;
      }

      final categories = [
        LogCategory.informational,
        LogCategory.warning,
        if (_debugEnabled) LogCategory.debug,
      ];

      setState(() {
        _logs.add(LogEntry(
          id: logId.toString(),
          timestamp: DateTime.now(),
          category: categories[logId % categories.length],
          message: _debugEnabled
              ? '[DEBUG] Processing iteration ${logId - 2}: portfolio_value=125000.50, position=LONG'
              : 'Processing iteration ${logId - 2}...',
          details: _debugEnabled
              ? 'Variable State:\nportfolio_value: 125000.50\ncurrent_position: LONG\nentry_price: 45.23'
              : null,
        ));
        logId++;
      });
    });
  }

  void _pauseBacktest() {
    setState(() {
      _isRunning = false;
      _progress = BacktestProgress(
        status: BacktestStatus.paused,
        progressPercentage: _progress.progressPercentage,
        elapsedSeconds: _progress.elapsedSeconds,
        backgroundSeconds: _progress.backgroundSeconds,
        activeSeconds: _progress.activeSeconds,
        estimatedRemainingSeconds: _progress.estimatedRemainingSeconds,
        startTime: _progress.startTime,
      );
    });
  }

  void _resumeBacktest() {
    _startBacktest();
  }

  void _stopBacktest() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Backtest?'),
        content: const Text(
            'Are you sure you want to stop the current backtest? Results will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isRunning = false;
                _progress = BacktestProgress(
                  status: BacktestStatus.stopped,
                  progressPercentage: _progress.progressPercentage,
                  elapsedSeconds: _progress.elapsedSeconds,
                );
              });
            },
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backtesting'),
        actions: [
          if (!_isRunning)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: _startBacktest,
              tooltip: 'Start Backtest',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Sheet Upload
            InputSheetUpload(
              onFileSelected: (file) {
                setState(() => _inputFile = file);
              },
              onTemplateSelected: (templateId) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Template selected: $templateId')),
                );
              },
              onRemove: () {
                setState(() => _inputFile = null);
              },
            ),
            const SizedBox(height: 16),

            // Debug Toggle
            DebugToggle(
              enabled: _debugEnabled,
              onChanged: (value) {
                setState(() => _debugEnabled = value);
              },
            ),
            const SizedBox(height: 16),

            // Progress Tracker
            ProgressTracker(
              progress: _progress,
              onPause: _pauseBacktest,
              onResume: _resumeBacktest,
              onStop: _stopBacktest,
              onViewDetails: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Progress Details'),
                    content: Text(
                      'Elapsed: ${_progress.formattedElapsedTime}\n'
                      'Active: ${_progress.formattedActiveTime}\n'
                      'Background: ${_progress.formattedBackgroundTime}\n'
                      'Progress: ${_progress.progressPercentage?.toStringAsFixed(1) ?? "N/A"}%',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Log Viewer
            SizedBox(
              height: 400,
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Live Logs',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Expanded(
                      child: LogViewer(
                        logs: _logs,
                        autoScroll: true,
                        showDebug: _debugEnabled,
                        onClear: () {
                          setState(() => _logs.clear());
                        },
                        onExport: (format) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Exporting logs as $format...')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
