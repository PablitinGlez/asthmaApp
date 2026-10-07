import 'dart:math';
import 'dart:typed_data';

/// Analiza el flujo PCM de una espiración forzada para:
/// 1) validar que realmente es un soplo (y no música/ruido), y
/// 2) extraer un "pico acústico" que después se convierte a PEF con la
///    calibración personal del paciente.
///
/// Un soplo forzado es ruido de banda ancha (alta tasa de cruces por cero),
/// con un ataque rápido y energía sostenida ~0.5-3s. La música o la voz son
/// tonales (baja tasa de cruces) o arrancan sin ataque claro.
class PefBlowAnalyzer {
  final int sampleRate;
  final int windowSamples;

  final List<_Frame> _frames = [];
  int _sampleCursor = 0;

  PefBlowAnalyzer({this.sampleRate = 44100, this.windowSamples = 1024});

  /// Reset antes de cada intento.
  void reset() {
    _frames.clear();
    _sampleCursor = 0;
  }

  int _pendingOffset = 0;
  final List<int> _pending = [];

  /// Alimenta bytes PCM16 little-endian. Devuelve el RMS de la última ventana
  /// procesada (para mostrar nivel en vivo), o 0 si aún no cierra una ventana.
  double addPcmChunk(Uint8List bytes) {
    double lastRms = 0;
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      final sample = (bytes[i] | (bytes[i + 1] << 8));
      final s = sample >= 0x8000 ? sample - 0x10000 : sample; // int16
      _pending.add(s);
      _sampleCursor++;
      if (_pending.length - _pendingOffset >= windowSamples) {
        final end = _pendingOffset + windowSamples;
        final frame = _processWindow(_pending, _pendingOffset, end);
        _frames.add(frame);
        lastRms = frame.rms;
        _pendingOffset = end;
        // liberar memoria acumulada periódicamente
        if (_pendingOffset > windowSamples * 40) {
          _pending.removeRange(0, _pendingOffset);
          _pendingOffset = 0;
        }
      }
    }
    return lastRms;
  }

  _Frame _processWindow(List<int> buf, int start, int end) {
    double sumSq = 0;
    int crossings = 0;
    int prev = buf[start];
    for (var i = start; i < end; i++) {
      final s = buf[i];
      sumSq += s * s;
      if ((prev >= 0) != (s >= 0)) crossings++;
      prev = s;
    }
    final n = end - start;
    final rms = sqrt(sumSq / n); // 0..32767
    final zcr = crossings / n; // 0..~0.5
    return _Frame(rms: rms, zcr: zcr);
  }

  /// RMS actual (última ventana) para UI en vivo.
  double get currentRms => _frames.isEmpty ? 0 : _frames.last.rms;

  /// Pico RMS acumulado (para UI en vivo).
  double get peakRms {
    var p = 0.0;
    for (final f in _frames) {
      if (f.rms > p) p = f.rms;
    }
    return p;
  }

  /// Resultado de un intento.
  PefBlowResult analyze() {
    if (_frames.isEmpty) {
      return PefBlowResult.invalid('No se capturó audio');
    }

    final peak = peakRms;
    if (peak < 1800) {
      return PefBlowResult.invalid(
        'No se detectó un soplo. Coloca el teléfono cerca de tu boca y sopla fuerte.',
      );
    }

    // Región activa: ventanas con energía >= 30% del pico.
    final threshold = peak * 0.3;
    final active = _frames.where((f) => f.rms >= threshold).toList();
    if (active.length < 6) {
      return PefBlowResult.invalid('El soplo fue muy corto. Sopla sostenido ~3 segundos.');
    }

    final firstActive = _frames.indexWhere((f) => f.rms >= threshold);
    final frameMs = windowSamples / sampleRate * 1000;
    final durationMs = active.length * frameMs;
    if (durationMs < 350) {
      return PefBlowResult.invalid('El soplo fue muy corto. Sopla sostenido ~3 segundos.');
    }

    // Ataque: tiempo desde el inicio de la región hasta llegar al 50% del pico.
    int attackIdx = -1;
    for (var i = firstActive; i < _frames.length; i++) {
      if (_frames[i].rms >= peak * 0.5) {
        attackIdx = i - firstActive;
        break;
      }
    }
    if (attackIdx < 0) attackIdx = active.length;
    final attackMs = attackIdx * frameMs;

    // Ruido de banda ancha = tasa de cruces por cero alta. Media de la región.
    double zcrSum = 0;
    for (final f in active) {
      zcrSum += f.zcr;
    }
    final meanZcr = active.isEmpty ? 0.0 : zcrSum / active.length;

    // Un soplo es ruido (zcr alto). Los soplos reales miden zcr ~0.3-0.45
    // (turbulencia de banda ancha); la música/voz tonales quedan muy por
    // debajo (~0.02-0.10). 0.18 separa bien ambos sin cortar soplos reales.
    final isBroadband = meanZcr >= 0.18;
    final hasAttack = firstActive > 1 && attackMs <= 500;

    if (!isBroadband) {
      return PefBlowResult.invalid(
        'Eso no parece un soplo. Sopla directo al micrófono (como limpiar gafas).',
      );
    }
    if (!hasAttack) {
      return PefBlowResult.invalid(
        'Hay demasiado ruido de fondo. Intenta en un lugar más silencioso.',
      );
    }

    return PefBlowResult.valid(peak, durationMs, meanZcr);
  }
}

class _Frame {
  final double rms;
  final double zcr;
  _Frame({required this.rms, required this.zcr});
}

class PefBlowResult {
  final bool isValid;
  final double acousticPeak;
  final double durationMs;
  final double meanZcr;
  final String? reason;

  PefBlowResult.valid(this.acousticPeak, this.durationMs, this.meanZcr)
      : isValid = true,
        reason = null;

  PefBlowResult.invalid(this.reason)
      : isValid = false,
        acousticPeak = 0,
        durationMs = 0,
        meanZcr = 0;
}