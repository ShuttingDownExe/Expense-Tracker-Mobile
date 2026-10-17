/// A single expense, mirroring the Expense Tracker API shape:
/// `{ id, date: "YYYY-MM-DD", description, amount, vendor, category, createdAt }`.
class Expense {
  final String id;
  final String date; // YYYY-MM-DD
  final String description;
  final double amount;
  final String vendor;
  final String? category;
  final int? createdAt; // server timestamp (ms)

  const Expense({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.vendor,
    this.category,
    this.createdAt,
  });

  /// Resolved category string, falling back to vendor for legacy data.
  String get categoryKey => (category != null && category!.isNotEmpty)
      ? category!
      : vendor;

  /// Firebase RTDB returns expenses keyed by id, so the id is passed in
  /// separately from the value object.
  factory Expense.fromJson(String id, Map<String, dynamic> json) {
    final cat = json['category'] as String?;
    final v = json['vendor'] as String? ?? '';
    return Expense(
      id: id,
      date: json['date'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      vendor: v,
      category: (cat != null && cat.isNotEmpty) ? cat : v,
      createdAt: (json['createdAt'] as num?)?.toInt(),
    );
  }

  /// Payload accepted by `POST /api/expenses`.
  Map<String, dynamic> toCreateJson() => {
        'description': description,
        'amount': amount,
        'vendor': vendor,
        if (category != null && category!.isNotEmpty) 'category': category,
        if (date.isNotEmpty) 'date': date,
      };

  DateTime get dateTime => DateTime.tryParse(date) ?? DateTime.now();
}
