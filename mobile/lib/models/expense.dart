import 'category.dart';

class Expense {
  final int id;
  final int userId;
  final int categoryId;
  final int amount; // En centavos
  final String currency;
  final String? merchant;
  final String? description;
  final DateTime expenseDate;
  final String status;
  final int? reportId;
  final String? receiptUrl;
  final DateTime createdAt;
  final Category? category;

  Expense({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.currency,
    this.merchant,
    this.description,
    required this.expenseDate,
    required this.status,
    this.reportId,
    this.receiptUrl,
    required this.createdAt,
    this.category,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      userId: json['user_id'],
      categoryId: json['category_id'],
      amount: json['amount'],
      currency: json['currency'] ?? 'USD',
      merchant: json['merchant'],
      description: json['description'],
      expenseDate: DateTime.parse(json['expense_date']),
      status: json['status'],
      reportId: json['report_id'],
      receiptUrl: json['receipt_url'],
      createdAt: DateTime.parse(json['created_at']),
      category: json['category'] != null 
          ? Category.fromJson(json['category']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'amount': amount,
      'currency': currency,
      'merchant': merchant,
      'description': description,
      'expense_date': expenseDate.toIso8601String(),
    };
  }

  double get amountInDollars => amount / 100.0;
}
