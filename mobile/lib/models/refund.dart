class Refund {
  final int id;
  final int tripId;
  final int? reportId;
  final int userId;
  
  final int budgetAmount;        // En centavos
  final int totalExpenses;       // En centavos
  final int excessAmount;        // En centavos
  final int refundedAmount;      // En centavos
  final int remainingAmount;     // En centavos
  final double refundPercentage;
  
  final String status;           // pending, partial, completed, waived, disputed, overdue
  final String? refundMethod;    // cash, transfer, payroll, check, other
  
  final DateTime? dueDate;
  final DateTime? completedDate;
  final bool isOverdue;
  
  final String? notes;
  final String? adminNotes;
  final String? waiveReason;
  final String? receiptUrl;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Información relacionada
  final String? tripName;
  final String? userName;
  final String? userEmail;

  Refund({
    required this.id,
    required this.tripId,
    this.reportId,
    required this.userId,
    required this.budgetAmount,
    required this.totalExpenses,
    required this.excessAmount,
    required this.refundedAmount,
    required this.remainingAmount,
    required this.refundPercentage,
    required this.status,
    this.refundMethod,
    this.dueDate,
    this.completedDate,
    required this.isOverdue,
    this.notes,
    this.adminNotes,
    this.waiveReason,
    this.receiptUrl,
    required this.createdAt,
    required this.updatedAt,
    this.tripName,
    this.userName,
    this.userEmail,
  });

  factory Refund.fromJson(Map<String, dynamic> json) {
    return Refund(
      id: json['id'],
      tripId: json['trip_id'],
      reportId: json['report_id'],
      userId: json['user_id'],
      budgetAmount: json['budget_amount'],
      totalExpenses: json['total_expenses'],
      excessAmount: json['excess_amount'],
      refundedAmount: json['refunded_amount'],
      remainingAmount: json['remaining_amount'],
      refundPercentage: (json['refund_percentage'] as num).toDouble(),
      status: json['status'],
      refundMethod: json['refund_method'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      completedDate: json['completed_date'] != null ? DateTime.parse(json['completed_date']) : null,
      isOverdue: json['is_overdue'],
      notes: json['notes'],
      adminNotes: json['admin_notes'],
      waiveReason: json['waive_reason'],
      receiptUrl: json['receipt_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      tripName: json['trip_name'],
      userName: json['user_name'],
      userEmail: json['user_email'],
    );
  }

  // Montos en dólares para UI
  double get budgetInDollars => budgetAmount / 100;
  double get totalExpensesInDollars => totalExpenses / 100;
  double get excessAmountInDollars => excessAmount / 100;
  double get refundedAmountInDollars => refundedAmount / 100;
  double get remainingAmountInDollars => remainingAmount / 100;

  // Estado para UI
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'partial':
        return 'Parcial';
      case 'completed':
        return 'Completado';
      case 'waived':
        return 'Exonerado';
      case 'disputed':
        return 'En Disputa';
      case 'overdue':
        return 'Vencido';
      default:
        return status;
    }
  }

  String get refundMethodDisplay {
    switch (refundMethod) {
      case 'cash':
        return 'Efectivo';
      case 'transfer':
        return 'Transferencia';
      case 'payroll':
        return 'Nómina';
      case 'check':
        return 'Cheque';
      case 'other':
        return 'Otro';
      default:
        return refundMethod ?? 'No especificado';
    }
  }

  // Días restantes para devolver
  int? get daysUntilDue {
    if (dueDate == null) return null;
    final difference = dueDate!.difference(DateTime.now()).inDays;
    return difference >= 0 ? difference : 0;
  }

  bool get isUrgent {
    if (daysUntilDue == null) return false;
    return daysUntilDue! <= 3 && status == 'pending';
  }
}
