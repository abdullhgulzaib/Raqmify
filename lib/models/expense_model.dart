class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String paymentMethod;
  final String notes;
  final String status;
  final String? userId;
  final String syncStatus; // synced, pending, failed (S5)

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.paymentMethod = 'Cash',
    this.notes = '',
    this.status = 'Completed',
    this.userId,
    this.syncStatus = 'synced',
  });

  ExpenseModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? paymentMethod,
    String? notes,
    String? status,
    String? userId,
    String? syncStatus,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return ExpenseModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Expense',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      category: json['category'] ?? 'General',
      date: parsedDate,
      paymentMethod: json['paymentMethod'] ?? 'Cash',
      notes: json['notes'] ?? '',
      status: json['status'] ?? 'Completed',
      userId: json['userId'] is String ? json['userId'] : (json['userId']?['_id'] ?? ''),
      syncStatus: json['syncStatus'] ?? 'synced',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'notes': notes,
      'status': status,
      'syncStatus': syncStatus,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          syncStatus == other.syncStatus;

  @override
  int get hashCode => id.hashCode ^ syncStatus.hashCode;
}
