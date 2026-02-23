import 'dart:async';
import 'package:flutter/foundation.dart';

/// Centralized time service for Demo Mode.
///
/// When [isDemo] is true, `now()` returns an accelerated simulated time
/// where 1 real minute = 1 simulated day (speedFactor = 1440).
///
/// When [isDemo] is false, `now()` returns real `DateTime.now()`.
class DemoClock extends ChangeNotifier {
  DemoClock();

  /// 1440× speed  →  1 real minute = 1 simulated day.
  static const double speedFactor = 1440.0;

  bool _isDemo = false;
  DateTime? _startRealTime;
  DateTime? _startSimTime;

  Timer? _tickTimer;

  bool get isDemo => _isDemo;

  /// Returns the current time — simulated if demo mode is on.
  DateTime now() {
    if (!_isDemo || _startRealTime == null || _startSimTime == null) {
      return DateTime.now();
    }
    final realElapsed = DateTime.now().difference(_startRealTime!);
    final simElapsed = Duration(
      microseconds: (realElapsed.inMicroseconds * speedFactor).round(),
    );
    return _startSimTime!.add(simElapsed);
  }

  /// Start demo mode. The simulated clock starts from [startFrom]
  /// (defaults to current real time).
  void start({DateTime? startFrom}) {
    _isDemo = true;
    _startRealTime = DateTime.now();
    _startSimTime = startFrom ?? DateTime.now();

    // Tick every second to notify listeners (for UI updates).
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });

    notifyListeners();
  }

  /// Stop demo mode and return to real time.
  void stop() {
    _isDemo = false;
    _tickTimer?.cancel();
    _tickTimer = null;
    notifyListeners();
  }

  /// Reset demo clock and restart from real time.
  void reset() {
    stop();
    start();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}
