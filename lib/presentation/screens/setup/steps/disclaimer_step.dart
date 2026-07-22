import 'package:flutter/material.dart';

class DisclaimerStep extends StatelessWidget {
  const DisclaimerStep({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.warning_amber_rounded,
            size: 80,
            color: Colors.orange,
          ),
          const SizedBox(height: 24),
          const Text(
            "Aviso Médico Importante",
            style: TextStyle(
              color: Colors.black87,
              fontFamily: 'Satoshi',
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "Esta aplicación NO sustituye el consejo, diagnóstico o tratamiento de un profesional médico.",
            style: TextStyle(
              color: Colors.grey.shade800,
              fontFamily: 'GeneralSans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              "AsthmaApp es solo una herramienta de predicción y registro de datos que puede cometer errores computacionales. Nunca ignores el consejo médico profesional ni demores en buscarlo debido a algo que hayas leído en esta aplicación. En caso de una emergencia médica o falta de aire grave, contacta de inmediato a tus servicios de emergencia locales o a tu doctor.",
              style: TextStyle(
                color: Colors.orange.shade900,
                fontFamily: 'GeneralSans',
                fontSize: 15,
                height: 1.6,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
          const SizedBox(height: 48),
          const Text(
            "Al presionar 'Finalizar' estás aceptando estos términos y asumes la responsabilidad del uso de la herramienta.",
            style: TextStyle(
              color: Colors.black54,
              fontFamily: 'Satoshi',
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
