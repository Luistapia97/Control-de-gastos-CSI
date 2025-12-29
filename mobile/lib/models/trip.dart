class Trip {
  final int id;
  final int userId;
  final String name;
  final String? destination;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final int? budget; // En centavos
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Trip({
    required this.id,
    required this.userId,
    required this.name,
    this.destination,
    required this.startDate,
    required this.endDate,
    this.description,
    this.budget,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      destination: json['destination'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      description: json['description'],
      budget: json['budget'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'destination': destination,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'description': description,
      'budget': budget,
    };
  }

  double get budgetInDollars => budget != null ? budget! / 100.0 : 0.0;

  String get statusDisplay {
    switch (status) {
      case 'active':
        return 'Activo';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  int get durationDays {
    return endDate.difference(startDate).inDays + 1;
  }

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
}
