import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../medications/providers/medications_provider.dart';

class NextDoseCard extends ConsumerWidget {
  const NextDoseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicationsProvider);
    
    // Si está cargando, mostramos un esqueleto simple
    if (state.isLoading) {
      return _buildBaseContainer(
        child: const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final activeMeds = state.medications.where((m) => m.isActive).toList();
    
    // Buscamos el medicamento más cercano
    activeMeds.sort((a, b) {
      if (a.nextDose == null) return 1;
      if (b.nextDose == null) return -1;
      return a.nextDose!.compareTo(b.nextDose!);
    });

    if (activeMeds.isEmpty || activeMeds.first.nextDose == null) {
      return _buildBaseContainer(
        onTap: () => context.push('/medications'),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'No tienes dosis programadas.',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      );
    }

    final med = activeMeds.first;
    final timeStr = DateFormat('HH:mm').format(med.nextDose!);
    final diff = med.nextDose!.difference(DateTime.now());
    
    String timeRemaining;
    if (diff.isNegative) {
      timeRemaining = 'atrasada';
    } else if (diff.inHours > 0) {
      timeRemaining = 'en ${diff.inHours}h ${diff.inMinutes % 60}min';
    } else {
      timeRemaining = 'en ${diff.inMinutes}min';
    }

    return _buildBaseContainer(
      onTap: () => context.push('/medications'),
      child: Row(
        children: [
          _buildIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Próxima dosis: ${med.name}',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$timeStr ($timeRemaining)',
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: diff.isNegative ? Colors.red.shade700 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildBaseContainer({required Widget child, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF023E8A).withOpacity(0.05),
              const Color(0xFF0077B6).withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF023E8A).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.medication_outlined,
        color: Color(0xFF023E8A),
        size: 24,
      ),
    );
  }
}
