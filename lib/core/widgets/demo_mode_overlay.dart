import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/demo_clock.dart';

/// Floating overlay showing simulated time and demo mode controls.
///
/// Place this in a [Stack] on top of your main content. It only appears
/// when [DemoClock.isDemo] is true, or when the user taps the FAB to
/// activate demo mode.
class DemoModeOverlay extends StatelessWidget {
  const DemoModeOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DemoClock>(
      builder: (context, clock, _) {
        return Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Expanded panel (only when demo is on)
              if (clock.isDemo) _DemoPanel(clock: clock),

              const SizedBox(height: 8),

              // FAB toggle
              FloatingActionButton.small(
                heroTag: 'demo_mode_fab',
                onPressed: () {
                  if (clock.isDemo) {
                    clock.stop();
                  } else {
                    clock.start();
                  }
                },
                backgroundColor: clock.isDemo ? Colors.red : Colors.deepPurple,
                child: Icon(
                  clock.isDemo ? Icons.stop : Icons.fast_forward,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DemoPanel extends StatelessWidget {
  const _DemoPanel({required this.clock});

  final DemoClock clock;

  @override
  Widget build(BuildContext context) {
    final simTime = clock.now();
    final dateStr = DateFormat('dd MMM yyyy').format(simTime);
    final timeStr = DateFormat('HH:mm:ss').format(simTime);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'DEMO MODE',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dateStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            timeStr,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '1 day = 1 min',
            style: TextStyle(
              color: Colors.orange.shade300,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: TextButton.icon(
              onPressed: () => clock.reset(),
              icon: const Icon(Icons.refresh, size: 14, color: Colors.white70),
              label: const Text(
                'Reset',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
