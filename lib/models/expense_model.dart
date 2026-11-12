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
  });

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'notes': notes,
      'status': status,
    };
  }
}
