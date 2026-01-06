import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/statistics_service.dart';
import '../services/user_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final StatisticsService _statisticsService = StatisticsService();
  final UserService _userService = UserService();
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  
  bool _isLoading = true;
  bool _isAdmin = false;
  String _selectedPeriod = '30'; // días
  
  Map<String, dynamic>? _overview;
  List<Map<String, dynamic>> _categoryData = [];
  List<Map<String, dynamic>> _monthlyData = [];
  List<Map<String, dynamic>> _topUsers = [];
  Map<String, dynamic>? _budgetCompliance;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await _userService.getCurrentUser();
      setState(() {
        _isAdmin = user['role'] == 'admin' || user['role'] == 'manager';
      });
      await _loadStatistics();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    
    try {
      // Calcular fechas según período seleccionado
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: int.parse(_selectedPeriod)));
      
      final overview = await _statisticsService.getOverview(
        startDate: startDate.toIso8601String().split('T')[0],
        endDate: endDate.toIso8601String().split('T')[0],
      );
      
      final categories = await _statisticsService.getExpensesByCategory(
        startDate: startDate.toIso8601String().split('T')[0],
        endDate: endDate.toIso8601String().split('T')[0],
      );
      
      final monthly = await _statisticsService.getMonthlyTrend(months: 6);
      final compliance = await _statisticsService.getBudgetCompliance();
      
      List<Map<String, dynamic>> topUsers = [];
      if (_isAdmin) {
        topUsers = await _statisticsService.getTopUsers(limit: 5);
      }
      
      setState(() {
        _overview = overview;
        _categoryData = categories;
        _monthlyData = monthly;
        _budgetCompliance = compliance;
        _topUsers = topUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar estadísticas: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
              _loadStatistics();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7', child: Text('Últimos 7 días')),
              const PopupMenuItem(value: '30', child: Text('Últimos 30 días')),
              const PopupMenuItem(value: '90', child: Text('Últimos 3 meses')),
              const PopupMenuItem(value: '180', child: Text('Últimos 6 meses')),
              const PopupMenuItem(value: '365', child: Text('Último año')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCards(),
                    const SizedBox(height: 24),
                    if (_categoryData.isNotEmpty) ...[
                      _buildCategoryChart(),
                      const SizedBox(height: 24),
                    ],
                    if (_monthlyData.isNotEmpty) ...[
                      _buildMonthlyTrendChart(),
                      const SizedBox(height: 24),
                    ],
                    if (_budgetCompliance != null) ...[
                      _buildBudgetComplianceCard(),
                      const SizedBox(height: 24),
                    ],
                    if (_isAdmin && _topUsers.isNotEmpty) ...[
                      _buildTopUsersCard(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    if (_overview == null) return const SizedBox();
    
    final totalSpent = (_overview!['total_spent'] ?? 0) / 100;
    final expensesCount = _overview!['expenses_count'] ?? 0;
    final activeTrips = _overview!['active_trips'] ?? 0;
    final pendingRefunds = (_overview!['pending_refunds'] ?? 0) / 100;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen General',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Gastado',
                currencyFormat.format(totalSpent),
                Icons.attach_money,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Gastos',
                expensesCount.toString(),
                Icons.receipt_long,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Viajes Activos',
                activeTrips.toString(),
                Icons.card_travel,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                _isAdmin ? 'A Devolver' : 'A Recibir',
                currencyFormat.format(pendingRefunds),
                Icons.account_balance_wallet,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gastos por Categoría',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: _categoryData.isEmpty
                  ? const Center(child: Text('Sin datos'))
                  : Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: PieChart(
                            PieChartData(
                              sections: _buildPieChartSections(),
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: _buildCategoryLegend(),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
    ];
    
    return List.generate(_categoryData.length, (index) {
      final category = _categoryData[index];
      final percentage = category['percentage'] ?? 0.0;
      final amount = (category['total_amount'] ?? 0) / 100;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildCategoryLegend() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
    ];
    
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _categoryData.length,
      itemBuilder: (context, index) {
        final category = _categoryData[index];
        final amount = (category['total_amount'] ?? 0) / 100;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category['category_name'] ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      currencyFormat.format(amount),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlyTrendChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tendencia Mensual',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: _monthlyData.isEmpty
                  ? const Center(child: Text('Sin datos'))
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  currencyFormat.format(value / 100),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < _monthlyData.length) {
                                  final month = _monthlyData[index]['month'];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      _getMonthAbbr(month),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _buildLineChartSpots(),
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildLineChartSpots() {
    return List.generate(_monthlyData.length, (index) {
      final amount = (_monthlyData[index]['total_amount'] ?? 0).toDouble();
      return FlSpot(index.toDouble(), amount);
    });
  }

  String _getMonthAbbr(int month) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return months[month - 1];
  }

  Widget _buildBudgetComplianceCard() {
    if (_budgetCompliance == null) return const SizedBox();
    
    final totalTrips = _budgetCompliance!['total_trips'] ?? 0;
    final withinBudget = _budgetCompliance!['within_budget'] ?? 0;
    final overBudget = _budgetCompliance!['over_budget'] ?? 0;
    final complianceRate = _budgetCompliance!['compliance_rate'] ?? 0.0;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cumplimiento de Presupuesto',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${complianceRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: complianceRate >= 70 ? Colors.green : Colors.orange,
                        ),
                      ),
                      const Text(
                        'Tasa de Cumplimiento',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            withinBudget.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Dentro del Presupuesto',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            overBudget.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Excedidos',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopUsersCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Usuarios con Más Gastos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _topUsers.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final user = _topUsers[index];
                final amount = (user['total_amount'] ?? 0) / 100;
                final count = user['expenses_count'] ?? 0;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user['user_name'] ?? 'Sin nombre',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '$count gastos',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: Text(
                    currencyFormat.format(amount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
