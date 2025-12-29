import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/refund.dart';
import '../services/refund_service.dart';
import '../services/user_service.dart';

class RefundListPage extends StatefulWidget {
  const RefundListPage({Key? key}) : super(key: key);

  @override
  State<RefundListPage> createState() => _RefundListPageState();
}

class _RefundListPageState extends State<RefundListPage> {
  final _refundService = RefundService();
  final _userService = UserService();
  List<Refund> _refunds = [];
  bool _isLoading = false;
  String? _selectedStatus;
  Map<String, dynamic>? _currentUser;
  bool _isAdmin = false;

  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadRefunds();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await _userService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isAdmin = user['role'] == 'admin' || user['role'] == 'manager';
      });
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> _loadRefunds() async {
    setState(() => _isLoading = true);
    try {
      final refunds = await _refundService.getRefunds(
        status: _selectedStatus,
      );
      setState(() {
        _refunds = refunds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar devoluciones: $e')),
        );
      }
    }
  }

  Future<void> _confirmPayment(Refund refund) async {
    // Mostrar diálogo para registrar el pago
    final TextEditingController amountController = TextEditingController(
      text: refund.remainingAmountInDollars.toStringAsFixed(2),
    );
    String? selectedMethod = 'transfer';
    final TextEditingController notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Pago al Usuario'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Usuario: ${refund.userName ?? "N/A"}'),
              Text('Monto pendiente: \$${refund.remainingAmountInDollars.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto a devolver',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Método de pago',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'transfer', child: Text('Transferencia')),
                  DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
                  DropdownMenuItem(value: 'payroll', child: Text('Nómina')),
                  DropdownMenuItem(value: 'check', child: Text('Cheque')),
                ],
                onChanged: (value) => selectedMethod = value,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Registrar Pago'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final amount = double.tryParse(amountController.text) ?? 0;
        if (amount <= 0) {
          throw Exception('Monto inválido');
        }

        await _refundService.recordPayment(
          refundId: refund.id,
          amount: (amount * 100).toInt(), // Convertir a centavos
          refundMethod: selectedMethod ?? 'transfer',
          notes: notesController.text.isEmpty ? null : notesController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Pago registrado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadRefunds();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al registrar pago: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'partial':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'waived':
        return Colors.purple;
      case 'overdue':
        return Colors.red;
      case 'disputed':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'partial':
        return Icons.trending_up;
      case 'completed':
        return Icons.check_circle;
      case 'waived':
        return Icons.verified;
      case 'overdue':
        return Icons.error;
      case 'disputed':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingRefunds = _refunds.where((r) => r.status == 'pending' || r.status == 'overdue').toList();
    final completedRefunds = _refunds.where((r) => r.status == 'completed' || r.status == 'waived').toList();
    final totalPending = pendingRefunds.fold<double>(0, (sum, r) => sum + r.remainingAmountInDollars);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devoluciones'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _selectedStatus = value == 'all' ? null : value);
              _loadRefunds();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Todas')),
              const PopupMenuItem(value: 'pending', child: Text('Pendientes')),
              const PopupMenuItem(value: 'partial', child: Text('Parciales')),
              const PopupMenuItem(value: 'completed', child: Text('Completadas')),
              const PopupMenuItem(value: 'waived', child: Text('Exoneradas')),
              const PopupMenuItem(value: 'overdue', child: Text('Vencidas')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Resumen
          if (_refunds.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: totalPending > 0
                      ? [Colors.orange.shade400, Colors.orange.shade600]
                      : [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _isAdmin ? 'Pagos Pendientes a Usuarios' : 'Reembolsos Pendientes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(totalPending),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isAdmin
                        ? '${pendingRefunds.length} ${pendingRefunds.length == 1 ? "usuario esperando reembolso" : "usuarios esperando reembolso"}'
                        : '${pendingRefunds.length} ${pendingRefunds.length == 1 ? "reembolso pendiente" : "reembolsos pendientes"}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          
          // Lista de devoluciones
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _refunds.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.money_off, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No hay devoluciones',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedStatus == null
                                  ? '¡Excelente! No tienes devoluciones pendientes'
                                  : 'No hay devoluciones con este filtro',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRefunds,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _refunds.length,
                          itemBuilder: (context, index) {
                            final refund = _refunds[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: refund.isUrgent
                                      ? Colors.red.shade300
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  // TODO: Navegación a detalle de devolución
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Vista de detalle próximamente')),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _getStatusIcon(refund.status),
                                            color: _getStatusColor(refund.status),
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  refund.tripName ?? 'Viaje sin nombre',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'Creada: ${dateFormat.format(refund.createdAt)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(refund.status),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              refund.statusDisplay,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _isAdmin ? 'A devolver' : 'A recibir',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Text(
                                                currencyFormat.format(refund.excessAmountInDollars),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (refund.status == 'partial')
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _isAdmin ? 'Ya devuelto' : 'Ya recibido',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  '${refund.refundPercentage.toStringAsFixed(0)}%',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      if (refund.dueDate != null && refund.status != 'completed' && refund.status != 'waived')
                                        Padding(
                                          padding: const EdgeInsets.only(top: 12),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 14,
                                                color: refund.isUrgent ? Colors.red : Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                refund.isOverdue
                                                    ? 'Vencido el ${dateFormat.format(refund.dueDate!)}'
                                                    : 'Vence: ${dateFormat.format(refund.dueDate!)} (${refund.daysUntilDue} días)',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: refund.isUrgent || refund.isOverdue
                                                      ? Colors.red
                                                      : Colors.grey[600],
                                                  fontWeight: refund.isUrgent || refund.isOverdue
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      // Información adicional para admins
                                      if (_isAdmin && refund.userName != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 12),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.person, size: 16, color: Colors.blue),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        refund.userName!,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      if (refund.userEmail != null)
                                                        Text(
                                                          refund.userEmail!,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      // Botones de acción para admin
                                      if (_isAdmin && (refund.status == 'pending' || refund.status == 'partial'))
                                        Padding(
                                          padding: const EdgeInsets.only(top: 12),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _confirmPayment(refund),
                                              icon: const Icon(Icons.payments, size: 18),
                                              label: Text(
                                                refund.status == 'partial'
                                                    ? 'Registrar Pago Adicional (\$${refund.remainingAmountInDollars.toStringAsFixed(2)})'
                                                    : 'Registrar Pago al Usuario (\$${refund.excessAmountInDollars.toStringAsFixed(2)})',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
