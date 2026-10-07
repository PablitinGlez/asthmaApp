import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/connectivity_provider.dart';

/// Banner superior que avisa cuando no hay conexión a internet.
/// Oculta cuando la conexión vuelve.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final isOnline = connectivity.value ?? true;

    if (isOnline) return const SizedBox.shrink();

    return Material(
      color: const Color(0xFF03045E),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_rounded,
                  color: Colors.amberAccent, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Sin conexión a internet. Mostrando datos guardados.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
