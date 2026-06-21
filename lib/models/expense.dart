/// A single expense, mirroring the Expense Tracker API shape:
/// `{ id, date: "YYYY-MM-DD", description, amount, vendor, createdAt }`.
class Expense {
  final String id;
  final String date; // YYYY-MM-DD
  final String description;
  final double amount;
  final String vendor;
  final int? createdAt; // server timestamp (ms)

  const Expense({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.vendor,
    this.createdAt,
  });

  /// Firebase RTDB returns expenses keyed by id, so the id is passed in
  /// separately from the value object.
  factory Expense.fromJson(String id, Map<String, dynamic> json) {
    return Expense(
      id: id,
      date: json['date'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      vendor: json['vendor'] as String? ?? '',
      createdAt: (json['createdAt'] as num?)?.toInt(),
    );
  }

  /// Payload accepted by `POST /api/expenses`. The schema is `.strict()` and
  /// accepts only these three fields — the server sets `date` automatically
  /// (today, in Asia/Kolkata). Sending `date` would fail validation.
  Map<String, dynamic> toCreateJson() => {
        'description': description,
        'amount': amount,
        'vendor': vendor,
      };

  DateTime get dateTime => DateTime.tryParse(date) ?? DateTime.now();
}
