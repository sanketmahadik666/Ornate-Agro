import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/auth_bloc.dart';

/// Manages session timeout and auto-logout
class SessionManager {
  SessionManager(this._context);

  final BuildContext _context;
  Timer? _sessionTimer;
  DateTime? _lastActivityTime;

  /// Initialize session timer
  void startSession() {
    _lastActivityTime = DateTime.now();
    _resetTimer();
  }

  /// Reset timer on user activity
  void resetTimer() {
    _lastActivityTime = DateTime.now();
    _resetTimer();
  }

  void _resetTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(
      Duration(minutes: AppConstants.sessionTimeoutMinutes),
      () => _handleTimeout(),
    );
  }

  void _handleTimeout() {
    if (_context.mounted) {
      final authBloc = _context.read<AuthBloc>();
      authBloc.add(const AuthSessionExpired());
      
      // Navigate to login if not already there
      Navigator.of(_context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
      
      ScaffoldMessenger.of(_context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please log in again.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Stop session timer
  void stopSession() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _lastActivityTime = null;
  }

  /// Dispose resources
  void dispose() {
    stopSession();
  }
}

/// Widget wrapper to manage session automatically
class SessionManagerWidget extends StatefulWidget {
  const SessionManagerWidget({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<SessionManagerWidget> createState() => _SessionManagerWidgetState();
}

class _SessionManagerWidgetState extends State<SessionManagerWidget> with WidgetsBindingObserver {
  SessionManager? _sessionManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionManager = SessionManager(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start session when widget is built
    final authState = context.watch<AuthBloc>().state;
    if (authState.status == AuthStatus.authenticated) {
      _sessionManager?.startSession();
    } else {
      _sessionManager?.stopSession();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sessionManager?.resetTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _sessionManager?.resetTimer(),
      child: widget.child,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionManager?.dispose();
    super.dispose();
  }
}
