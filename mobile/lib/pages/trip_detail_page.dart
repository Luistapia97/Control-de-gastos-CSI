import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../services/expense_service.dart';
import '../services/trip_service.dart';
import '../services/report_service.dart';
import 'create_expense_page.dart';
import 'edit_expense_page.dart';
import 'report_detail_page.dart';

class TripDetailPage extends StatefulWidget {
  final Trip trip;

  const TripDetailPage({Key? key, required this.trip}) : super(key: key);

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  final _expenseService = ExpenseService();
  final _tripService = TripService();
  final _reportService = ReportService();
  List<Expense> _expenses = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  bool _isGeneratingReport = false;
  bool _isLoadingReport = false;
  late Trip _trip;

  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final expenses = await _expenseService.getExpenses(tripId: _trip.id);
      final categories = await _expenseService.getCategories();
      setState(() {
        _expenses = expenses;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar gastos: $e')),
        );
      }
    }
  }

  double get totalExpenses {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.amountInDollars);
  }

  double get budgetUsedPercentage {
    if (_trip.budget == null || _trip.budget == 0) return 0;
    return (totalExpenses / _trip.budgetInDollars) * 100;
  }

  String _getCategoryName(int categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId).name;
    } catch (e) {
      return 'Categoría';
    }
  }

  String _getCategoryIcon(int categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId).icon;
    } catch (e) {
      return '📄';
    }
  }

  Future<void> _editExpense(Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpensePage(
          expense: expense,
          tripId: _trip.id,
        ),
      ),
    );
    if (result == true) {
      _loadExpenses();
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Gasto'),
        content: Text(
          '¿Estás seguro de eliminar este gasto de ${currencyFormat.format(expense.amountInDollars)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _expenseService.deleteExpense(expense.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gasto eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadExpenses();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar gasto: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Aprobado';
      case 'rejected':
        return 'Rechazado';
      case 'pending':
        return 'Pendiente';
      case 'draft':
        return 'Borrador';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_trip.name),
        actions: [
          if (_trip.isActive)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'generate_report') {
                  // Generar reporte automáticamente
                  if (_expenses.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('El viaje no tiene gastos para generar un reporte'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Generar Reporte'),
                      content: Text(
                        'Se generará un reporte con todos los ${_expenses.length} gastos de este viaje. ¿Desea continuar?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Generar'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    setState(() => _isGeneratingReport = true);
                    try {
                      final report = await _reportService.generateReportFromTrip(_trip.id);
                      setState(() => _isGeneratingReport = false);
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Reporte "${report.name}" generado exitosamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        // Navegar al reporte generado
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportDetailPage(reportId: report.id),
                          ),
                        );
                      }
                    } catch (e) {
                      setState(() => _isGeneratingReport = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al generar reporte: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                } else if (value == 'complete') {
                  // Confirmación antes de completar
                  final confirmComplete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Completar Viaje'),
                      content: const Text(
                        '¿Marcar este viaje como completado?\n\n'
                        '• Se generará/actualizará automáticamente el reporte con todos los gastos\n'
                        '• No podrás agregar más gastos a este viaje',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Completar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmComplete == true) {
                    try {
                      final updatedTrip = await _tripService.completeTrip(_trip.id);
                      setState(() => _trip = updatedTrip);
                      await _loadExpenses(); // Recargar gastos
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Viaje completado y reporte actualizado'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  }
                } else if (value == 'view_report') {
                  setState(() => _isLoadingReport = true);
                  try {
                    final report = await _tripService.getTripReport(_trip.id);
                    setState(() => _isLoadingReport = false);
                    
                    if (report != null && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportDetailPage(reportId: report.id),
                        ),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Este viaje no tiene un reporte asociado'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  } catch (e) {
                    setState(() => _isLoadingReport = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al cargar reporte: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                if (!_trip.isCompleted)
                  const PopupMenuItem(
                    value: 'generate_report',
                    child: Row(
                      children: [
                        Icon(Icons.description, size: 20),
                        SizedBox(width: 8),
                        Text('Generar Reporte'),
                      ],
                    ),
                  ),
                if (!_trip.isCompleted)
                  const PopupMenuItem(
                    value: 'complete',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 20, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Marcar como completado'),
                      ],
                    ),
                  ),
                if (_trip.isCompleted)
                  const PopupMenuItem(
                    value: 'view_report',
                    child: Row(
                      children: [
                        Icon(Icons.assignment, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Ver Reporte del Viaje'),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Trip Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _trip.isActive
                    ? [Colors.blue.shade400, Colors.blue.shade600]
                    : [Colors.grey.shade400, Colors.grey.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_trip.destination != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        _trip.destination!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Text(
                  '${dateFormat.format(_trip.startDate)} - ${dateFormat.format(_trip.endDate)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${_trip.durationDays} días • ${_trip.statusDisplay}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                if (_trip.budget != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Presupuesto',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              currencyFormat.format(_trip.budgetInDollars),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Gastado',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              currencyFormat.format(totalExpenses),
                              style: TextStyle(
                                color: budgetUsedPercentage > 100
                                    ? Colors.red.shade200
                                    : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: budgetUsedPercentage / 100,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              budgetUsedPercentage > 100
                                  ? Colors.red
                                  : budgetUsedPercentage > 80
                                      ? Colors.orange
                                      : Colors.green,
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${budgetUsedPercentage.toStringAsFixed(1)}% utilizado',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Mensaje de viaje completado
          if (_trip.isCompleted)
            Container(
              color: Colors.green.shade50,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Viaje completado. No se pueden agregar más gastos.',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoadingReport ? null : () async {
                          setState(() => _isLoadingReport = true);
                          try {
                            final report = await _tripService.getTripReport(_trip.id);
                            setState(() => _isLoadingReport = false);
                            
                            if (report != null && mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReportDetailPage(reportId: report.id),
                                ),
                              );
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Este viaje no tiene un reporte asociado'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => _isLoadingReport = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al cargar reporte: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: _isLoadingReport 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.assignment),
                        label: Text(_isLoadingReport 
                            ? 'Cargando...' 
                            : 'Ver Reporte del Viaje'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Expenses List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _expenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No hay gastos en este viaje',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            const Text('Agrega tu primer gasto'),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadExpenses,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _expenses.length,
                          itemBuilder: (context, index) {
                            final expense = _expenses[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    _getCategoryIcon(expense.categoryId),
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                                title: Text(
                                  expense.merchant ?? _getCategoryName(expense.categoryId),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_getCategoryName(expense.categoryId)),
                                    Text(
                                      dateFormat.format(expense.expenseDate),
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          currencyFormat.format(expense.amountInDollars),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(expense.status),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            _getStatusText(expense.status),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!_trip.isCompleted)
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, size: 20),
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _editExpense(expense);
                                          } else if (value == 'delete') {
                                            _deleteExpense(expense);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, size: 20, color: Colors.blue),
                                                SizedBox(width: 8),
                                                Text('Editar'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, size: 20, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Eliminar'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _trip.isCompleted 
          ? null 
          : FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateExpensePage(tripId: _trip.id),
                  ),
                );
                if (result == true) {
                  _loadExpenses();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Gasto'),
            ),
    );
  }
}
