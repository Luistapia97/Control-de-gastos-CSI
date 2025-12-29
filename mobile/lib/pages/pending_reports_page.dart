import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import 'report_detail_page.dart';

class PendingReportsPage extends StatefulWidget {
  const PendingReportsPage({Key? key}) : super(key: key);

  @override
  State<PendingReportsPage> createState() => _PendingReportsPageState();
}

class _PendingReportsPageState extends State<PendingReportsPage> {
  final _reportService = ReportService();
  List<Report> _reports = [];
  bool _isLoading = false;

  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await _reportService.getPendingReports();
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar reportes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveReport(Report report) async {
    final TextEditingController commentsController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar Reporte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Está seguro que desea aprobar el reporte "${report.name}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: commentsController,
              decoration: const InputDecoration(
                labelText: 'Comentarios (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bool success = false;
      String? errorMessage;
      try {
        await _reportService.approveReport(
          report.id,
          comments: commentsController.text.isNotEmpty
              ? commentsController.text
              : null,
        );
        success = true;
      } catch (e) {
        errorMessage = e.toString();
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reporte aprobado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadReports();
        } else if (errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al aprobar reporte: $errorMessage'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectReport(Report report) async {
    final TextEditingController commentsController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Reporte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Está seguro que desea rechazar el reporte "${report.name}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: commentsController,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _reportService.rejectReport(
          report.id,
          comments: commentsController.text.isNotEmpty
              ? commentsController.text
              : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reporte rechazado'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadReports();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al rechazar reporte: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes Pendientes'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay reportes pendientes',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: ListView.builder(
                    itemCount: _reports.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final report = _reports[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Icon(Icons.pending_actions,
                                    color: Colors.white),
                              ),
                              title: Text(
                                report.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (report.description != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      report.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.attach_money,
                                          size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        currencyFormat
                                            .format(report.totalInDollars),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.receipt_long,
                                          size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text('${report.expenseCount} gastos'),
                                    ],
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReportDetailPage(
                                      reportId: report.id,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _loadReports();
                                }
                              },
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _approveReport(report),
                                      icon: const Icon(Icons.check_circle,
                                          size: 18),
                                      label: const Text('Aprobar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _rejectReport(report),
                                      icon: const Icon(Icons.cancel, size: 18),
                                      label: const Text('Rechazar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
