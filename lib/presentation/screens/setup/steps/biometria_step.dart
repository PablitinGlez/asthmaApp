import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/setup_form_provider.dart';

class BiometriaStep extends ConsumerStatefulWidget {
  const BiometriaStep({super.key});

  @override
  ConsumerState<BiometriaStep> createState() => _BiometriaStepState();
}

class _BiometriaStepState extends ConsumerState<BiometriaStep> {
  // Datos locales para la UI
  String _selectedGender = 'male'; // 'male' or 'female'
  double _heightCm = 170.0;
  final TextEditingController _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ageController.addListener(_updateProvider);
  }

  @override
  void dispose() {
    _ageController.removeListener(_updateProvider);
    _ageController.dispose();
    super.dispose();
  }

  String? _ageError;

  void _updateProvider() {
    final text = _ageController.text;
    if (text.isEmpty) {
      if (_ageError != null) setState(() => _ageError = null);
      ref.read(setupFormProvider.notifier).setBiometria(
          gender: _selectedGender, age: 25, heightCm: _heightCm);
      return;
    }

    final age = int.tryParse(text);
    if (age == null || age <= 0 || age > 130) {
      if (_ageError != 'Edad inválida (1-130)') {
        setState(() => _ageError = 'Edad inválida (1-130)');
      }
      ref.read(setupFormProvider.notifier).setBiometria(
          gender: _selectedGender, age: 25, heightCm: _heightCm);
    } else {
      if (_ageError != null) setState(() => _ageError = null);
      ref.read(setupFormProvider.notifier).setBiometria(
          gender: _selectedGender, age: age, heightCm: _heightCm);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITULO
          const Text(
            "Cuéntanos de ti",
            style: TextStyle(
              color: Colors.black87,
              fontFamily: 'Satoshi', // Tu fuente principal
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Necesitamos esto para calcular tu capacidad pulmonar teórica (PEF).",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontFamily: 'GeneralSans', // Tu fuente secundaria
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),

          // 1. GÉNERO (Tarjetas Seleccionables)
          Text(
            "Género Biológico",
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Satoshi',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GenderCard(
                  icon: Icons.male,
                  label: "Hombre",
                  isSelected: _selectedGender == 'male',
                  onTap: () {
                    setState(() => _selectedGender = 'male');
                    _updateProvider();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _GenderCard(
                  icon: Icons.female,
                  label: "Mujer",
                  isSelected: _selectedGender == 'female',
                  onTap: () {
                    setState(() => _selectedGender = 'female');
                    _updateProvider();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 2. EDAD (Input Numérico Simple)
          Text(
            "Edad",
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Satoshi',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16, // Reducido para match Login
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w400, // Normal weight como en Login
            ),
            decoration: InputDecoration(
              hintText: "Ej: 25",
              hintStyle: TextStyle(
                color: Colors.grey.shade400, // Match Login hint
                fontSize: 14, // Match Login hint size
                fontFamily: 'Satoshi',
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              errorText: _ageError,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF023E8A),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixText: "años",
              suffixStyle: TextStyle(
                color: Colors.grey.shade500,
                fontFamily: 'Satoshi',
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 3. ALTURA (Slider Visual)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Altura",
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Satoshi',
                ),
              ),
              Text(
                "${_heightCm.round()} cm",
                style: const TextStyle(
                  color: Color(0xFF023E8A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Satoshi',
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF023E8A),
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: const Color(0xFF023E8A),
              overlayColor: const Color(0xFF023E8A).withOpacity(0.1),
              trackHeight: 6.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
            ),
            child: Slider(
              value: _heightCm,
              min: 100,
              max: 230,
              divisions: 130,
              label: "${_heightCm.round()} cm",
              onChanged: (value) {
                setState(() {
                  _heightCm = value;
                });
                _updateProvider();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Widget Auxiliar Local para las tarjetas de género
class _GenderCard extends StatelessWidget {
  final IconData icon; // Restored Icon
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.icon, // Restored Icon
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF023E8A).withOpacity(0.05)
              : Colors.white, // Fondo activo/inactivo
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF023E8A)
                : Colors.grey.shade300, // Borde brillante si seleccionado
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? const Color(0xFF023E8A)
                  : Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF023E8A)
                    : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 16,
                fontFamily: 'Satoshi',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
