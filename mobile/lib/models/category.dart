class Category {
  final int id;
  final String name;
  final String icon;
  final String color;
  final int? maxAmount;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.maxAmount,
    required this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      color: json['color'],
      maxAmount: json['max_amount'],
      isActive: json['is_active'] ?? true,
    );
  }
}
