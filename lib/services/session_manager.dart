import 'package:flutter/widgets.dart';
import 'auth_service.dart';

class SessionManager extends WidgetsBindingObserver {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  bool _isInitialized = false;
  VoidCallback? _onSessionExpired;

  void initialize({VoidCallback? onSessionExpired}) {
    if (_isInitialized) return;

    _onSessionExpired = onSessionExpired;
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;

    // Update last active time when app starts
    AuthService.updateLastActiveTime();
  }

  void dispose() {
    if (!_isInitialized) return;

    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
    _onSessionExpired = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
        // Handle inactive state if needed
        break;
      case AppLifecycleState.hidden:
        // Handle hidden state if needed
        break;
    }
  }

  Future<void> _handleAppResumed() async {
    // Check if session is still valid when app resumes
    final isSessionValid = await AuthService.isSessionValid();

    if (!isSessionValid) {
      // Session expired, trigger callback
      _onSessionExpired?.call();
    } else {
      // Session is still valid, update last active time
      await AuthService.updateLastActiveTime();
    }
  }

  Future<void> _handleAppPaused() async {
    // Update last active time when app is paused
    await AuthService.updateLastActiveTime();
  }

  Future<void> _handleAppDetached() async {
    // Clear session when app is completely detached
    await AuthService.clearSession();
  }

  // Method to manually check session validity
  Future<bool> checkSession() async {
    final isSessionValid = await AuthService.isSessionValid();

    if (!isSessionValid) {
      _onSessionExpired?.call();
    }

    return isSessionValid;
  }

  // Method to update activity (call when user interacts with app)
  Future<void> updateActivity() async {
    await AuthService.updateLastActiveTime();
  }
}

// Mixin for widgets that need to track session activity
mixin SessionTrackerMixin<T extends StatefulWidget> on State<T> {
  final SessionManager _sessionManager = SessionManager();

  @override
  void initState() {
    super.initState();
    _setupSessionTracking();
  }

  void _setupSessionTracking() {
    // Update activity on user interactions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sessionManager.updateActivity();
    });
  }

  // Call this method when user performs any action
  void trackUserActivity() {
    _sessionManager.updateActivity();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
