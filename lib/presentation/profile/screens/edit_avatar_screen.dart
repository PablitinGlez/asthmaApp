import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_notifier.dart';

class EditAvatarScreen extends ConsumerStatefulWidget {
  const EditAvatarScreen({super.key});

  @override
  ConsumerState<EditAvatarScreen> createState() => _EditAvatarScreenState();
}

class _EditAvatarScreenState extends ConsumerState<EditAvatarScreen> {
  
  late String _currentSeed;
  late String _currentBackground;
  bool _isSaving = false;

  
  final List<Color> _predefinedColors = [
    const Color(0xFFB6E3F4), 
    const Color(0xFFFFE5B4), 
    const Color(0xFFD4F1D4), 
    const Color(0xFFFFD4E5), 
  ];

  @override
  void initState() {
    super.initState();
    
    final user = ref.read(authStateProvider).value;
    _currentSeed = user?.fullName ?? 'Usuario';
    _currentBackground = user?.avatarBackground ?? '023e8a';
  }

  void _changeBackgroundColor(Color color) {
    setState(() {
      _currentBackground = color.value
          .toRadixString(16)
          .padLeft(8, '0')
          .substring(2);
    });
  }

  String _getAvatarUrl() {
    
    return 'https://api.dicebear.com/9.x/initials/svg?'
        'seed=$_currentSeed&'
        'backgroundColor=$_currentBackground';
  }

  void _saveAvatar() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      
      
      await ref
          .read(authNotifierProvider.notifier)
          .updateAvatar(
            avatarSeed: _currentSeed,
            avatarBackground: _currentBackground,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showColorPicker() {
    Color pickerColor = Color(int.parse('FF$_currentBackground', radix: 16));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Elige un color',
          style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) {
              pickerColor = color;
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Satoshi'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentBackground = pickerColor.value
                    .toRadixString(16)
                    .padLeft(8, '0')
                    .substring(2);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF023E8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Seleccionar',
              style: TextStyle(fontFamily: 'Satoshi'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Personalizar Avatar',
          style: TextStyle(
            color: Colors.black87,
            fontFamily: 'Satoshi',
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[100],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: SvgPicture.network(
                    _getAvatarUrl(),
                    fit: BoxFit.cover,
                    placeholderBuilder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),

            const Text(
              'Color de Fondo',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _predefinedColors.map((color) {
                final colorHex = color.value
                    .toRadixString(16)
                    .padLeft(8, '0')
                    .substring(2);
                final isSelected = _currentBackground == colorHex;
                return GestureDetector(
                  onTap: () => _changeBackgroundColor(color),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF023E8A)
                            : Colors.grey.shade200,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            
            TextButton.icon(
              onPressed: _showColorPicker,
              icon: const Icon(Icons.colorize_rounded),
              label: const Text('Más colores'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF023E8A),
                textStyle: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 48),

            
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAvatar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF023E8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Guardar Cambios',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
