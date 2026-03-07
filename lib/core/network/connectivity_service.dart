import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

// ════════════════════════════════════════════════════════════
//  ConnectivityService  –  singleton network monitor
// ════════════════════════════════════════════════════════════
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;
  ConnectivityService._();

  final _connectivity = Connectivity();
  bool _isOnline = true;

  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  Stream<bool> get onConnectivityChanged => _controller.stream;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    // Check initial state
    final results = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(results as List<ConnectivityResult>);

    // Listen for changes
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = _isConnected(results as List<ConnectivityResult>);
      if (wasOnline != _isOnline) {
        _controller.add(_isOnline);
      }
    }) as StreamSubscription<List<ConnectivityResult>>?;
  }

  bool _isConnected(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  Future<bool> checkNow() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(results as List<ConnectivityResult>);
    return _isOnline;
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
