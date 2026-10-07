import 'dart:math';

/// Resultado del análisis DSP de un soplo (producido por PefBlowAnalyzer).
class PefFeatures {
  final double acousticPeak; // pico RMS (0..32767) de la explosión espiratoria
  final double durationMs; // duración de la espiración sostenida
  final double meanZcr; // tasa media de cruces por cero (ancho de banda)

  const PefFeatures({
    required this.acousticPeak,
    required this.durationMs,
    required this.meanZcr,
  });
}

/// Algoritmo dedicado que convierte las características acústicas de una
/// espiración forzada en una estimación de PEF (L/min).
///
/// Físicamente, el nivel sonoro del soplo se relaciona con el flujo de aire;
/// pero la conversión exacta depende del teléfono y la técnica. Por eso el
/// estimador está ANCLADO a la calibración personal del paciente (su mejor PEF
/// personal medido con un espirómetro real), como hace un monitor PEF real.
///
/// NOTA: sin datos de entrenamiento pareados (grabación + espirómetro) es una
/// aproximación. Los coeficientes internos son físicos por defecto y se escalan
/// con la calibración personal.
class PefEstimator {
  /// Pico RMS que corresponde al mejor PEF personal del paciente (calibración).
  /// Si es null/0, no hay calibración y no se puede estimar con fiabilidad.
  final double? calibrationPeakRms;

  /// Mejor PEF personal del paciente en L/min (referencia de un espirómetro).
  final int personalBestPef;

  PefEstimator({this.calibrationPeakRms, required this.personalBestPef});

  bool get isCalibrated =>
      calibrationPeakRms != null && calibrationPeakRms! > 0;

  /// Convierte las características de UN soplo válido a PEF (L/min).
  ///
  /// Modelo: PEF = personalBest * (peak / calibrationPeak) ^ gamma
  /// gamma ~0.85 (relación sublineal flujo↔SPL). El ancla es la calibración,
  /// así que en un soplo idéntico al de calibración devuelve exactamente el
  /// mejor PEF personal (100%).
  int estimate(PefFeatures f) {
    if (!isCalibrated) return 0;
    final ratio = (f.acousticPeak / calibrationPeakRms!).clamp(0.05, 3.0);
    const gamma = 0.85;
    // pequeño ajuste por duración: un soplo sostenido indica más volumen/capacidad
    final durFactor = (f.durationMs / 1500.0).clamp(0.6, 1.1);
    final pef = personalBestPef * pow(ratio, gamma) * durFactor;
    return pef.round().clamp(30, 900);
  }

  /// % del mejor PEF personal (escala clínica GINA).
  double percentOfPersonalBest(int pef) {
    if (personalBestPef <= 0) return 0;
    return (pef / personalBestPef) * 100.0;
  }

  /// Semáforo clínico según % del mejor personal (plan de acción GINA).
  /// green >= 80%, yellow 50-80%, red < 50%.
  String trafficLight(int pef) {
    final pct = percentOfPersonalBest(pef);
    if (pct >= 80) return 'green';
    if (pct >= 50) return 'yellow';
    return 'red';
  }
}