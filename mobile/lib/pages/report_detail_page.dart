import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/report.dart';
import '../models/expense.dart';
import '../services/report_service.dart';
import '../services/expense_service.dart';
import '../services/export_service.dart';

class ReportDetailPage extends StatefulWidget {
  final int reportId;

  const ReportDetailPage({
    Key? key,
    required this.reportId,
  }) : super(key: key);

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final _reportService = ReportService();
  final _expenseService = ExpenseService();
  final _exportService = ExportService();
  
  Report? _report;
  List<Expense> _expenses = [];
  List<Expense> _availableExpenses = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _reportService.getReport(widget.reportId);
      final availableExpenses = await _expenseService.getExpenses();
      
      setState(() {
        _report = data['report'] as Report;
        _expenses = data['expenses'] as List<Expense>;
        // Filtrar solo gastos sin reporte asignado
        _availableExpenses = availableExpenses
            .where((e) => e.reportId == null)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddExpenseDialog() async {
    if (_availableExpenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay gastos disponibles para agregar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Gasto'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableExpenses.length,
            itemBuilder: (context, index) {
              final expense = _availableExpenses[index];
              return ListTile(
                title: Text(expense.merchant ?? 'Sin comercio'),
                subtitle: Text(
                  '\$${(expense.amount / 100).toStringAsFixed(2)} - ${expense.category?.name ?? ''}',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _addExpense(expense.id);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _addExpense(int expenseId) async {
    try {
      await _reportService.addExpenseToReport(
        reportId: widget.reportId,
        expenseId: expenseId,
      );
      await _loadReportData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Gasto agregado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeExpense(int expenseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar Gasto'),
        content: const Text('¿Estás seguro de quitar este gasto del reporte?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _reportService.removeExpenseFromReport(
          reportId: widget.reportId,
          expenseId: expenseId,
        );
        await _loadReportData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Gasto removido'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _submitReport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar Reporte'),
        content: const Text(
          '¿Enviar este reporte para aprobación? No podrás editarlo después.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSubmitting = true);
      try {
        await _reportService.submitReport(widget.reportId);
        await _loadReportData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Reporte enviado para aprobación'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _exportToPDF() async {
    if (_report == null) return;
    
    setState(() => _isExporting = true);
    try {
      final file = await _exportService.downloadPDFFromBackend(widget.reportId);
      setState(() => _isExporting = false);
      
      if (mounted && file != null) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✓ PDF Descargado'),
            content: Text('El archivo se guardó en:\n${file.path}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Abrir'),
              ),
            ],
          ),
        );
        
        if (result == true) {
          await _exportService.openFile(file.path);
        }
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToCSV() async {
    if (_report == null) return;
    
    setState(() => _isExporting = true);
    try {
      final file = await _exportService.downloadExcelFromBackend(widget.reportId);
      setState(() => _isExporting = false);
      
      if (mounted && file != null) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✓ Excel Descargado'),
            content: Text('El archivo se guardó en:\n${file.path}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Abrir'),
              ),
            ],
          ),
        );
        
        if (result == true) {
          await _exportService.openFile(file.path);
        }
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Exportar a PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportToPDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Exportar a Excel'),
              onTap: () {
                Navigator.pop(context);
                _exportToCSV();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'submitted':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Reporte no encontrado')),
      );
    }

    final dateFormat = DateFormat('dd MMM yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Reporte'),
        actions: [
          if (_report!.canEdit)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddExpenseDialog,
              tooltip: 'Agregar gasto',
            ),
          IconButton(
            icon: _isExporting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download),
            onPressed: _isExporting ? null : _showExportOptions,
            tooltip: 'Exportar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReportData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header con info del reporte
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getStatusColor(_report!.status),
                      _getStatusColor(_report!.status).withOpacity(0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _report!.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _report!.statusDisplay.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_report!.description != null &&
                        _report!.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _report!.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              currencyFormat.format(_report!.totalInDollars),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'GASTOS',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '${_report!.expenseCount}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Fechas
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Creado',
                        dateFormat.format(_report!.createdAt),
                        Icons.calendar_today,
                      ),
                    ),
                    if (_report!.submittedAt != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          'Enviado',
                          dateFormat.format(_report!.submittedAt!),
                          Icons.send,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Lista de gastos
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Gastos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_report!.canEdit)
                          TextButton.icon(
                            onPressed: _showAddExpenseDialog,
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Agregar'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_expenses.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No hay gastos en este reporte',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                if (_report!.canEdit) ...[
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _showAddExpenseDialog,
                                    child: const Text('Agregar primer gasto'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ..._expenses.map((expense) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Text(
                                  expense.category?.icon ?? '📄',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              title: Text(
                                expense.merchant ?? 'Sin comercio',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                '${expense.category?.name ?? ''} • ${DateFormat('dd/MM/yyyy').format(expense.expenseDate)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    currencyFormat.format(expense.amount / 100),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  if (_report!.canEdit) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      color: Colors.red,
                                      onPressed: () => _removeExpense(expense.id),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )),
                  ],
                ),
              ),

              // Botón de enviar
              if (_report!.canSubmit)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitReport,
                    icon: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isSubmitting
                        ? 'Enviando...'
                        : 'Enviar para Aprobación'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
