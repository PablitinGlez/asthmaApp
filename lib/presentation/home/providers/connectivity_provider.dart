import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Expone si el dispositivo tiene conexión a internet en tiempo real.
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();

  final controller = StreamController<bool>();

  Stream<List<ConnectivityResult>> stream() => connectivity.onConnectivityChanged;

  stream().listen((results) {
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    if (!controller.isClosed) controller.add(isOnline);
  });

  connectivity.checkConnectivity().then((results) {
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    if (!controller.isClosed) controller.add(isOnline);
  });

  ref.onDispose(controller.close);

  return controller.stream;
});
