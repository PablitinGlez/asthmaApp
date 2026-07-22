import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/setup_form_provider.dart';

class HistorialStep extends ConsumerStatefulWidget {
  const HistorialStep({super.key});

  @override
  ConsumerState<HistorialStep> createState() => _HistorialStepState();
}

class _HistorialStepState extends ConsumerState<HistorialStep> {
  final TextEditingController _pefController = TextEditingController();
  bool _showTheoretical = false;

  // Valor simulado (En realidad vendría de la lógica biometrica anterior)
  final int _theoreticalPEF = 540;

  @override
  void initState() {
    super.initState();
    _pefController.addListener(_updateProvider);
  }

  @override
  void dispose() {
    _pefController.removeListener(_updateProvider);
    _pefController.dispose();
    super.dispose();
  }

  String? _pefError;

  void _updateProvider() {
    final text = _pefController.text;
    if (text.isEmpty) {
      if (_pefError != null) setState(() => _pefError = null);
      return;
    }

    final pef = int.tryParse(text);
    if (pef == null || pef < 50 || pef > 1000) {
      if (_pefError != 'PEF inválido (50-1000)') {
        setState(() => _pefError = 'PEF inválido (50-1000)');
      }
    } else {
      if (_pefError != null) setState(() => _pefError = null);
      ref.read(setupFormProvider.notifier).setHistorial(pef: pef);
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
            "Tu Historial",
            style: TextStyle(
              color: Colors.black87,
              fontFamily: 'Satoshi',
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Para calibrar el semáforo de riesgo, necesitamos saber tu 'Mejor Marca Personal' (Personal Best).",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontFamily: 'GeneralSans',
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),

          // PREGUNTA PRINCIPAL
          Center(
            child: Column(
              children: [
                Text(
                  "¿Cuál es tu mejor PEF registrado?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Satoshi',
                  ),
                ),
                const SizedBox(height: 16),

                // INPUT GIGANTE
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    controller: _pefController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF023E8A),
                      fontSize: 48,
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: "000",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 48,
                        fontFamily: 'Satoshi',
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      errorText: _pefError,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color(0xFF023E8A),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "L/min",
                  style: TextStyle(
                    color: Color(0xFF023E8A),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'Satoshi',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // SECCIÓN DE AYUDA (CALCULO TEÓRICO)
          if (!_showTheoretical)
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showTheoretical = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    "No lo sé, calcular un aproximado",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

          if (_showTheoretical)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF023E8A).withOpacity(0.05),
                border: Border.all(
                  color: const Color(0xFF023E8A).withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    "Basado en tu edad (25) y altura (175cm):",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$_theoreticalPEF L/min",
                    style: const TextStyle(
                      color: Color(0xFF023E8A),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _pefController.text = _theoreticalPEF.toString();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF023E8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Usar este valor",
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
