import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/smartwatch_provider.dart';
import 'dart:ui' as ui;

class SmartwatchLinkingBanner extends StatelessWidget {
  final SmartwatchState watchState;
  final WidgetRef ref;

  const SmartwatchLinkingBanner({
    super.key,
    required this.watchState,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDenied = watchState.isPermanentlyDenied;

    return GestureDetector(
      onTap: () {
        if (!watchState.isLoading) {
          if (isDenied) {
            ref.read(smartwatchProvider.notifier).openSettings();
          } else {
            ref.read(smartwatchProvider.notifier).linkSmartwatch();
          }
        }
      },
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: isDenied ? Colors.red.shade300 : Colors.grey.shade400,
          strokeWidth: 1.5,
          gap: 6.0,
          radius: 20.0,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: isDenied
                ? Colors.red.shade50.withOpacity(0.5)
                : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(
                isDenied ? Icons.settings_applications : Icons.watch_rounded,
                color: isDenied ? Colors.red.shade400 : Colors.grey.shade400,
                size: 40,
              ),
              const SizedBox(height: 12),
              if (watchState.isLoading)
                const CircularProgressIndicator(strokeWidth: 2)
              else ...[
                Text(
                  isDenied ? 'Permisos Bloqueados' : 'Monitorea tus Vítales',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDenied ? Colors.red.shade700 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDenied
                      ? 'Toca para abrir la configuración de tu dispositivo y habilitar permisos de salud manualmente.'
                      : 'Toca para vincular tu Smartwatch e iniciar el monitoreo automático.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 13,
                    color: isDenied
                        ? Colors.red.shade600
                        : Colors.grey.shade500,
                  ),
                ),
              ],
              
              // Consola de Logs para Depuración (Solicitada por el usuario)
              if (watchState.logs.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: Colors.black12),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'LOGS DE DIAGNÓSTICO',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black45,
                        letterSpacing: 1.2,
                      ),
                    ),
                    InkWell(
                      onTap: () => ref.read(smartwatchProvider.notifier).clearLogs(),
                      child: const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 120, // Altura fija para no romper el layout
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: watchState.logs.length,
                    itemBuilder: (context, index) {
                      final log = watchState.logs[index];
                      final isError = log.contains('[ERROR]') || log.contains('[FATAL]');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: isError ? Colors.red.shade700 : Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Toma captura a estos logs si falla la vinculación.',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
    this.radius = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    var path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    Path dashPath = Path();
    for (ui.PathMetric measurePath in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < measurePath.length) {
        final len = draw ? gap : gap;
        if (draw) {
          dashPath.addPath(
            measurePath.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
