import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/appearance_provider.dart';
import '../../../core/theme/app_theme.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final containerColor =
        isDark ? const Color(0xFF1A1A22) : Colors.white;
    final mutedColor = scheme.onSurfaceVariant;
    final borderColor = scheme.outlineVariant.withValues(alpha: 0.7);

    return Scaffold(
      appBar: AppBar(title: const Text('Apariencia')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          _buildSectionTitle(context, 'Modo'),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildModeOption(
                context,
                label: 'Claro',
                icon: Icons.light_mode_outlined,
                selected: appearance.themeMode == ThemeMode.light,
                onTap: () =>
                    ref.read(appearanceProvider.notifier).setThemeMode(ThemeMode.light),
              ),
              const SizedBox(width: 12),
              _buildModeOption(
                context,
                label: 'Oscuro',
                icon: Icons.dark_mode_outlined,
                selected: appearance.themeMode == ThemeMode.dark,
                onTap: () =>
                    ref.read(appearanceProvider.notifier).setThemeMode(ThemeMode.dark),
              ),
              const SizedBox(width: 12),
              _buildModeOption(
                context,
                label: 'Sistema',
                icon: Icons.brightness_auto_outlined,
                selected: appearance.themeMode == ThemeMode.system,
                onTap: () =>
                    ref.read(appearanceProvider.notifier).setThemeMode(ThemeMode.system),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'Color de acento'),
          const SizedBox(height: 12),
          Text(
            'El color se aplica en toda la aplicación: botones, indicadores y gráficas.',
            style: TextStyle(fontFamily: 'GeneralSans', fontSize: 13, color: mutedColor),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final color in kAccentPalette)
                _buildSwatch(
                  context,
                  color: color,
                  selected: color.toARGB32() == appearance.seedColor.toARGB32(),
                  onTap: () =>
                      ref.read(appearanceProvider.notifier).setSeedColor(color),
                ),
              _buildCustomSwatch(
                context,
                containerColor: containerColor,
                borderColor: borderColor,
                onTap: () => _pickCustomColor(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'Vista previa'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.favorite, color: scheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estado general',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Todo bajo control',
                            style: TextStyle(
                              fontFamily: 'GeneralSans',
                              fontSize: 13,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Estable',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A22) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? scheme.primary : scheme.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.primary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwatch(
    BuildContext context, {
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.onSurface : Colors.transparent,
            width: 2.4,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: selected ? 10 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
            : null,
      ),
    );
  }

  Widget _buildCustomSwatch(
    BuildContext context, {
    required Color containerColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: containerColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.4),
        ),
        child: Icon(
          Icons.palette_outlined,
          color: scheme.onSurfaceVariant,
          size: 24,
        ),
      ),
    );
  }

  Future<void> _pickCustomColor(BuildContext context, WidgetRef ref) async {
    final current = ref.read(appearanceProvider).seedColor;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showDialog<Color>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Color personalizado'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: current,
            onColorChanged: (_) {},
            enableAlpha: false,
            hexInputBar: true,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: scheme.primary),
            onPressed: () => Navigator.of(dialogContext).pop(current),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (picked != null) {
      await ref.read(appearanceProvider.notifier).setSeedColor(picked);
    }
  }
}