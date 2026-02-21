import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ReportExportService {
  static final _dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');

  /// Exports a given 2D list of strings to CSV and prompts the user to share/save it.
  Future<void> exportToCsv({
    required String title,
    required List<List<String>> data,
  }) async {
    final csvString = const ListToCsvConverter().convert(data);
    final directory = await getTemporaryDirectory();
    final timestamp = _dateFormat.format(DateTime.now());
    final fileName = '${title.replaceAll(' ', '_')}_$timestamp.csv';

    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvString);

    await Share.shareXFiles([XFile(file.path)], text: '$title (CSV)');
  }

  /// Exports a given 2D list of strings to PDF and prompts the user to share/save it.
  Future<void> exportToPdf({
    required String title,
    required List<List<String>> data,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(title,
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: data.isNotEmpty ? data.first : [],
              data: data.length > 1 ? data.sublist(1) : [],
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.all(5),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ];
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final timestamp = _dateFormat.format(DateTime.now());
    final fileName = '${title.replaceAll(' ', '_')}_$timestamp.pdf';

    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: '$title (PDF)');
  }
}
