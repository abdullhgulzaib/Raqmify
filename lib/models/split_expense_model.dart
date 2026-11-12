class SplitMemberShare {
  final String userId;
  final String name;
  final String email;
  final double amount;
  final double percentage;
  final String status; // Unpaid, UnderReview, Verified, Settled, Paid
  final String? proofTid;
  final String? proofImageUrl;
  final String? paymentMethod;

  SplitMemberShare({
    required this.userId,
    required this.name,
    this.email = '',
    required this.amount,
    this.percentage = 0.0,
    this.status = 'Unpaid',
    this.proofTid,
    this.proofImageUrl,
    this.paymentMethod,
  });

  factory SplitMemberShare.fromJson(Map<String, dynamic> json) {
    final proof = json['proof'] as Map<String, dynamic>?;
    return SplitMemberShare(
      userId: json['user'] is String ? json['user'] : (json['user']?['_id'] ?? ''),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      percentage: (json['percentage'] is num) ? (json['percentage'] as num).toDouble() : 0.0,
      status: json['status'] ?? 'Unpaid',
      proofTid: proof?['transactionId'] ?? proof?['tid'],
      proofImageUrl: proof?['imageUrl'] ?? proof?['receiptUrl'],
      paymentMethod: proof?['paymentMethod'],
    );
  }
}

class SplitExpenseModel {
  final String id;
  final String title;
  final double totalAmount;
  final String category;
  final String paidByUserId;
  final String paidByName;
  final String? groupId;
  final String groupName;
  final String splitType; // Equal, Percentage, Custom
  final DateTime date;
  final String notes;
  final bool isFullySettled;
  final List<SplitMemberShare> splits;

  SplitExpenseModel({
    required this.id,
    required this.title,
    required this.totalAmount,
    this.category = 'Food',
    required this.paidByUserId,
    required this.paidByName,
    this.groupId,
    this.groupName = '',
    this.splitType = 'Equal',
    required this.date,
    this.notes = '',
    this.isFullySettled = false,
    required this.splits,
  });

  factory SplitExpenseModel.fromJson(Map<String, dynamic> json) {
    var rawSplits = json['splits'] as List<dynamic>? ?? [];
    List<SplitMemberShare> parsedSplits = rawSplits
        .map((s) => SplitMemberShare.fromJson(s as Map<String, dynamic>))
        .toList();

    DateTime parsedDate;
    try {
      parsedDate = json['date'] != null ? DateTime.parse(json['date']) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return SplitExpenseModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Shared Expense',
      totalAmount: (json['totalAmount'] is num) ? (json['totalAmount'] as num).toDouble() : 0.0,
      category: json['category'] ?? 'Food',
      paidByUserId: json['paidBy'] is String ? json['paidBy'] : (json['paidBy']?['_id'] ?? ''),
      paidByName: json['paidByName'] ?? '',
      groupId: json['groupId'] is String ? json['groupId'] : (json['groupId']?['_id'] ?? ''),
      groupName: json['groupName'] ?? '',
      splitType: json['splitType'] ?? 'Equal',
      date: parsedDate,
      notes: json['notes'] ?? '',
      isFullySettled: json['isFullySettled'] ?? false,
      splits: parsedSplits,
    );
  }
}
