import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/report.dart';
import '../models/expense.dart';

class ExportService {
  final dateFormat = DateFormat('dd/MM/yyyy');
  final currencyFormat = NumberFormat.currency(symbol: '\$');

  Future<String> exportToPDF(Report report, List<Expense> expenses) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    report.name,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Estado: ${report.statusDisplay}',
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.white,
                    ),
                  ),
                  if (report.description != null && report.description!.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    pw.Text(
                      report.description!,
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Información del reporte
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  _buildInfoRow('Fecha de creación:', dateFormat.format(report.createdAt)),
                  pw.SizedBox(height: 8),
                  _buildInfoRow('Última actualización:', dateFormat.format(report.updatedAt)),
                  pw.SizedBox(height: 8),
                  _buildInfoRow('Total de gastos:', '${expenses.length}'),
                  pw.SizedBox(height: 8),
                  _buildInfoRow('Monto total:', currencyFormat.format(report.totalInDollars)),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Tabla de gastos
            pw.Text(
              'Gastos',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),

            if (expenses.isEmpty)
              pw.Text('No hay gastos en este reporte')
            else
              pw.TableHelper.fromTextArray(
                headers: ['Fecha', 'Comercio', 'Categoría', 'Monto'],
                data: expenses.map((expense) => [
                  dateFormat.format(expense.expenseDate),
                  expense.merchant ?? 'Sin comercio',
                  expense.category?.name ?? 'Sin categoría',
                  currencyFormat.format(expense.amount / 100),
                ]).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(8),
              ),

            pw.SizedBox(height: 20),

            // Footer
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Generado el ${dateFormat.format(DateTime.now())}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey,
              ),
            ),
          ];
        },
      ),
    );

    // Guardar el archivo
    final output = await getApplicationDocumentsDirectory();
    final fileName = 'Reporte_${report.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(value),
      ],
    );
  }

  Future<String> exportToCSV(Report report, List<Expense> expenses) async {
    List<List<dynamic>> rows = [];

    // Encabezado del reporte
    rows.add(['REPORTE: ${report.name}']);
    rows.add(['Estado', report.statusDisplay]);
    if (report.description != null && report.description!.isNotEmpty) {
      rows.add(['Descripción', report.description]);
    }
    rows.add(['Fecha creación', dateFormat.format(report.createdAt)]);
    rows.add(['Última actualización', dateFormat.format(report.updatedAt)]);
    rows.add(['Total gastos', expenses.length]);
    rows.add(['Monto total', currencyFormat.format(report.totalInDollars)]);
    rows.add([]); // Línea vacía

    // Encabezado de la tabla de gastos
    rows.add(['Fecha', 'Comercio', 'Categoría', 'Monto', 'Descripción']);

    // Datos de gastos
    for (var expense in expenses) {
      rows.add([
        dateFormat.format(expense.expenseDate),
        expense.merchant ?? 'Sin comercio',
        expense.category?.name ?? 'Sin categoría',
        (expense.amount / 100).toStringAsFixed(2),
        expense.description ?? '',
      ]);
    }

    // Convertir a CSV
    String csv = const ListToCsvConverter().convert(rows);

    // Guardar el archivo
    final output = await getApplicationDocumentsDirectory();
    final fileName = 'Reporte_${report.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${output.path}/$fileName');
    await file.writeAsString(csv);

    return file.path;
  }

  Future<void> openFile(String filePath) async {
    await OpenFile.open(filePath);
  }

  // Métodos para descargar desde el backend
  final String baseUrl = 'http://192.168.100.53:8000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<File?> downloadPDFFromBackend(int reportId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$baseUrl/reports/$reportId/export/pdf'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Pedir permiso de almacenamiento
        if (await Permission.storage.request().isGranted ||
            await Permission.manageExternalStorage.request().isGranted) {
          
          // Obtener directorio de descargas
          Directory? directory;
          if (Platform.isAndroid) {
            directory = Directory('/storage/emulated/0/Download');
            if (!await directory.exists()) {
              directory = await getExternalStorageDirectory();
            }
          } else {
            directory = await getApplicationDocumentsDirectory();
          }

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final filePath = '${directory!.path}/reporte_$reportId\_$timestamp.pdf';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);
          
          return file;
        } else {
          throw Exception('Permiso de almacenamiento denegado');
        }
      } else {
        throw Exception('Error al descargar PDF: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<File?> downloadExcelFromBackend(int reportId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$baseUrl/reports/$reportId/export/excel'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Pedir permiso de almacenamiento
        if (await Permission.storage.request().isGranted ||
            await Permission.manageExternalStorage.request().isGranted) {
          
          // Obtener directorio de descargas
          Directory? directory;
          if (Platform.isAndroid) {
            directory = Directory('/storage/emulated/0/Download');
            if (!await directory.exists()) {
              directory = await getExternalStorageDirectory();
            }
          } else {
            directory = await getApplicationDocumentsDirectory();
          }

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final filePath = '${directory!.path}/reporte_$reportId\_$timestamp.xlsx';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);
          
          return file;
        } else {
          throw Exception('Permiso de almacenamiento denegado');
        }
      } else {
        throw Exception('Error al descargar Excel: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
