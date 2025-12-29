class Report {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final int expenseCount;
  final int totalAmount;

  Report({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
    this.expenseCount = 0,
    this.totalAmount = 0,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      userId: json['user_id'],
      name: json['title'] ?? json['name'] ?? '',  // Acepta 'title' del backend
      description: json['description'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      submittedAt: json['submitted_at'] != null 
          ? DateTime.parse(json['submitted_at']) 
          : null,
      expenseCount: json['expense_count'] ?? 0,
      totalAmount: json['total_amount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': name,  // Enviar como 'title' al backend
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'expense_count': expenseCount,
      'total_amount': totalAmount,
    };
  }

  // Getters útiles
  double get totalInDollars => totalAmount / 100.0;

  String get statusDisplay {
    switch (status) {
      case 'draft':
        return 'Borrador';
      case 'submitted':
        return 'Enviado';
      case 'approved':
        return 'Aprobado';
      case 'rejected':
        return 'Rechazado';
      default:
        return status;
    }
  }

  bool get isDraft => status == 'draft';
  bool get isSubmitted => status == 'submitted';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get canEdit => status == 'draft';
  bool get canSubmit => status == 'draft' && expenseCount > 0;
}
