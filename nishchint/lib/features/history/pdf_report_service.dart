import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class PdfReportService {
  static Future<File> generate({
    required Map<String, dynamic> reportData,
  }) async {
    final pdf = pw.Document();
    
    final font = await PdfGoogleFonts.nunitoBold();
    final fontRegular = await PdfGoogleFonts.nunitoRegular();

    final patient = reportData['patient'];
    final medicines = reportData['medicines'] as List;
    final overallAdherence = reportData['overall_adherence_percent'];
    final dateRange = reportData['date_range'];
    final generatedAt = reportData['report_generated_at'];

    final primaryColor = PdfColor.fromInt(0xFFFF7F50); // Coral-ish

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Nishchint (निश्चिंत)', style: pw.TextStyle(font: font, fontSize: 24, color: primaryColor)),
                  pw.Text('Medicine Adherence Report', style: pw.TextStyle(font: fontRegular, fontSize: 14, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Generated: $generatedAt', style: pw.TextStyle(font: fontRegular, fontSize: 10)),
                  pw.Text('Range: ${dateRange['from']} to ${dateRange['to']}', style: pw.TextStyle(font: fontRegular, fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(thickness: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 10),

          // Patient Info
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Patient: ${patient['name']}', style: pw.TextStyle(font: font, fontSize: 16)),
                    pw.Text('Conditions: ${patient['conditions'] ?? 'N/A'}', style: pw.TextStyle(font: fontRegular, fontSize: 12)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Prepared for: Dr. ${patient['doctor_name'] ?? 'Not Specified'}', style: pw.TextStyle(font: fontRegular, fontSize: 12)),
                    pw.Text('Emergency: ${patient['emergency_contact'] ?? 'N/A'}', style: pw.TextStyle(font: fontRegular, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Medicines Table
          pw.Text('Medicines & Adherence', style: pw.TextStyle(font: font, fontSize: 18)),
          pw.SizedBox(height: 10),
          
          ...medicines.map((med) {
            final adherence = med['adherence'];
            final percent = adherence['adherence_percent'];
            final color = percent > 80 ? PdfColors.green : (percent > 50 ? PdfColors.orange : PdfColors.red);

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 15),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text(med['name'], style: pw.TextStyle(font: font, fontSize: 14)),
                          pw.SizedBox(width: 8),
                          if (med['is_critical'] == true)
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: const pw.BoxDecoration(color: PdfColors.red, borderRadius: pw.BorderRadius.all(pw.Radius.circular(4))),
                              child: pw.Text('CRITICAL', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, font: font)),
                            ),
                        ],
                      ),
                      pw.Text('${med['form'].toString().toUpperCase()}', style: pw.TextStyle(fontSize: 10, font: fontRegular, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('Dose: ${med['dose']} (${med['food_timing'].toString().replaceAll('_', ' ')})', style: pw.TextStyle(font: fontRegular, fontSize: 11)),
                  pw.SizedBox(height: 5),
                  pw.Text('Schedule: ' + (med['schedules'] as List).map((s) => '${s['time_slot']} (${s['label']})').join(', '), style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey700)),
                  pw.SizedBox(height: 8),
                  
                  // Adherence Bar
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          height: 8,
                          decoration: const pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.all(pw.Radius.circular(4))),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                width: (percent / 100) * 150, // Simplified bar
                                decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.all(pw.Radius.circular(4))),
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Text('$percent%', style: pw.TextStyle(font: font, fontSize: 12, color: color)),
                      pw.SizedBox(width: 10),
                      pw.Text('Taken: ${adherence['taken']} / Skip: ${adherence['skipped']} / Snooze: ${adherence['snoozed']}', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),

          pw.SizedBox(height: 20),

          // Summary Box
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Overall Adherence', style: pw.TextStyle(font: fontRegular, fontSize: 14)),
                    pw.Text('$overallAdherence%', style: pw.TextStyle(font: font, fontSize: 32, color: overallAdherence > 80 ? PdfColors.green : (overallAdherence > 50 ? PdfColors.orange : PdfColors.red))),
                  ],
                ),
              ],
            ),
          ),
          
          pw.Spacer(),
          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
          pw.Center(
            child: pw.Text('Generated by Nishchint — nishchint.yuktaa.com', style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey500)),
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/doctor_report_${patient['name'].toString().replaceAll(' ', '_')}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
