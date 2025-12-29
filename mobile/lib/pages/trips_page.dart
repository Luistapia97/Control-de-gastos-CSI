import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import 'create_trip_page.dart';
import 'trip_detail_page.dart';
import 'reports_page.dart';
import 'pending_reports_page.dart';
import 'users_page.dart';
import 'login_page.dart';
import 'refund_list_page.dart';
import 'statistics_page.dart';
import 'notifications_page.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({Key? key}) : super(key: key);

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  final TripService _tripService = TripService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();
  List<Trip> _trips = [];
  bool _isLoading = false;
  String? _selectedStatus = 'active'; // Iniciar con "activos" por defecto
  Map<String, dynamic>? _currentUser;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    print('DEBUG: TripsPage initState called');
    _loadUserInfo();
    _loadTrips();
    _loadUnreadNotifications();
  }

  Future<void> _loadUserInfo() async {
    print('DEBUG: Starting _loadUserInfo');
    try {
      final user = await _userService.getCurrentUser();
      print('DEBUG: User loaded: ${user['email']}');
      if (!mounted) return;
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      print('DEBUG: Error loading user: $e');
      // Error silencioso
    }
  }

  bool get _isAdmin => _currentUser?['role']?.toLowerCase() == 'admin';
  bool get _isManagerOrAdmin {
    final role = _currentUser?['role']?.toLowerCase();
    return role == 'admin' || role == 'manager';
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() => _unreadNotifications = count);
      }
    } catch (e) {
      print('Error loading unread notifications: $e');
    }
  }

  Future<void> _loadTrips() async {
    print('DEBUG: Starting _loadTrips');
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      print('DEBUG: Calling tripService.getTrips...');
      final trips = await _tripService.getTrips(status: _selectedStatus);
      print('DEBUG: Trips loaded: ${trips.length} trips');
      if (!mounted) return;
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
      print('DEBUG: State updated, isLoading=false');
    } catch (e) {
      print('DEBUG: Error in _loadTrips: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar viajes: $e')),
        );
      }
    }
  }

  Future<void> _deleteTrip(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Viaje'),
        content: Text(
          '¿Estás seguro de que deseas eliminar el viaje "${trip.name}"?\n\n'
          'Esta acción no se puede deshacer. Se eliminarán todos los gastos y reportes asociados.',
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
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _tripService.deleteTrip(trip.id);
        _loadTrips();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Viaje eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar viaje: $e'),
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
        title: Text(_selectedStatus == 'active' ? 'Viajes Activos' : 'Viajes Completados'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                  _loadUnreadNotifications();
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotifications > 99 ? '99+' : _unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedStatus = value;
              });
              _loadTrips();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'active', child: Text('Activos')),
              const PopupMenuItem(value: 'completed', child: Text('Completados')),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'reports') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportsPage()),
                );
              } else if (value == 'pending_reports') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PendingReportsPage()),
                );
              } else if (value == 'refunds') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RefundListPage()),
                );
              } else if (value == 'statistics') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StatisticsPage()),
                );
              } else if (value == 'users') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UsersPage()),
                );
              } else if (value == 'logout') {
                await _authService.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reports',
                child: Row(
                  children: [
                    Icon(Icons.description, size: 20),
                    SizedBox(width: 8),
                    Text('Mis Reportes'),
                  ],
                ),
              ),
              if (_isManagerOrAdmin)
                const PopupMenuItem(
                  value: 'pending_reports',
                  child: Row(
                    children: [
                      Icon(Icons.pending_actions, size: 20, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Reportes Pendientes'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'refunds',
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, size: 20, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Devoluciones'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'statistics',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Estadísticas'),
                  ],
                ),
              ),
              if (_isAdmin)
                const PopupMenuItem(
                  value: 'users',
                  child: Row(
                    children: [
                      Icon(Icons.people, size: 20, color: Colors.purple),
                      SizedBox(width: 8),
                      Text('Usuarios'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTrips,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _trips.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flight_takeoff, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _selectedStatus == 'active' 
                              ? 'No hay viajes activos'
                              : 'No hay viajes completados',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedStatus == 'active'
                              ? 'Crea tu primer viaje para organizar gastos'
                              : 'Los viajes completados aparecerán aquí',
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _trips.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final trip = _trips[index];
                      return _buildTripCard(trip);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTripPage()),
          );
          if (result == true) {
            _loadTrips();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isCompletedView = _selectedStatus == 'completed';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TripDetailPage(trip: trip),
            ),
          ).then((_) => _loadTrips());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: trip.isActive ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      trip.isActive ? Icons.flight_takeoff : Icons.check_circle,
                      color: trip.isActive ? Colors.blue : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (trip.destination != null)
                          Text(
                            trip.destination!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isCompletedView)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTrip(trip),
                      tooltip: 'Eliminar viaje',
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(trip.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        trip.statusDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${trip.durationDays} días',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              if (trip.budget != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Presupuesto: \$${trip.budgetInDollars.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
              if (trip.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  trip.description!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
