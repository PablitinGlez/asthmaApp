import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../domain/measurements/entities/measurement_history_item.dart';

class PdfService {
  static Future<void> generateMeasurementsReport({
    required String userName,
    required List<MeasurementHistoryItem> history,
  }) async {
    final pdf = pw.Document();

    const double pb = 450.0;

    final total = history.length;
    final bestAllTime = history.isNotEmpty
        ? history.map((e) => e.pef ?? 0).reduce((a, b) => a > b ? a : b)
        : 0;

    final greenCount = history.where((h) => (h.pef ?? 0) >= pb * 0.8).length;
    final yellowCount = history
        .where((h) => (h.pef ?? 0) < pb * 0.8 && (h.pef ?? 0) >= pb * 0.5)
        .length;
    final redCount = history
        .where((h) => (h.pef ?? 0) > 0 && (h.pef ?? 0) < pb * 0.5)
        .length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Reporte de Seguimiento de Asma',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'AsthmaApp',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 16),

            pw.Row(
              children: [
                pw.Expanded(child: _buildInfoBox('Paciente', userName)),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: _buildInfoBox('Total de Registros', total.toString()),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: _buildInfoBox(
                    'Mejor PEF Registrado',
                    '$bestAllTime L/min',
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            pw.Text(
              'Resumen de Estado General',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusCard(
                  'Zona Verde',
                  greenCount.toString(),
                  PdfColors.green700,
                ),
                pw.SizedBox(width: 12),
                _buildStatusCard(
                  'Zona Amarilla',
                  yellowCount.toString(),
                  PdfColors.amber700,
                ),
                pw.SizedBox(width: 12),
                _buildStatusCard(
                  'Zona Roja',
                  redCount.toString(),
                  PdfColors.red700,
                ),
              ],
            ),
            pw.SizedBox(height: 32),

            pw.Text(
              'Historial Detallado de Mediciones',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),

            pw.Table.fromTextArray(
              border: null,
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
                borderRadius: pw.BorderRadius.vertical(
                  top: pw.Radius.circular(4),
                ),
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                ),
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.center,
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(3),
              },
              headers: [
                'Fecha y Hora',
                'PEF (L/min)',
                'Zona',
                'Síntomas y Notas',
              ],
              data: history.map((m) {
                final dateStr = DateFormat(
                  'dd/MM/yy HH:mm',
                ).format(m.measuredAt.toLocal());
                final pef = m.pef ?? 0;
                String zoneLabel = 'Roja';
                if (pef >= pb * 0.8)
                  zoneLabel = 'Verde';
                else if (pef >= pb * 0.5)
                  zoneLabel = 'Amarilla';

                final symptoms = (m.symptoms ?? '').split('|')[0];
                final notes = m.notes ?? '';
                final detail = symptoms.isNotEmpty
                    ? '$symptoms ${notes.isNotEmpty ? "($notes)" : ""}'
                    : (notes.isEmpty ? '--' : notes);

                return [dateStr, '$pef', zoneLabel, detail];
              }).toList(),
            ),

            pw.SizedBox(height: 40),
            pw.Footer(
              trailing: pw.Text(
                'Nota: Este reporte es orientativo. Por favor, consulte siempre con su médico.',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Reporte_Asma_${userName.replaceAll(" ", "_")}.pdf',
    );
  }

  static pw.Widget _buildInfoBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatusCard(
    String label,
    String count,
    PdfColor color,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              count,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.Text(
              'registros',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ],
        ),
      ),
    );
  }
}
