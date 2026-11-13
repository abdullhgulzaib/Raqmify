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

  SplitMemberShare copyWith({
    String? userId,
    String? name,
    String? email,
    double? amount,
    double? percentage,
    String? status,
    String? proofTid,
    String? proofImageUrl,
    String? paymentMethod,
  }) {
    return SplitMemberShare(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
      status: status ?? this.status,
      proofTid: proofTid ?? this.proofTid,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  factory SplitMemberShare.fromJson(Map<String, dynamic> json) {
    final proof = json['proof'] as Map<String, dynamic>?;

    String resolvedUserId = '';
    if (json['userId'] != null && json['userId'].toString().isNotEmpty) {
      resolvedUserId = json['userId'].toString();
    } else if (json['user'] != null) {
      if (json['user'] is String) {
        resolvedUserId = json['user'];
      } else if (json['user'] is Map) {
        resolvedUserId = json['user']['_id']?.toString() ?? json['user']['id']?.toString() ?? '';
      }
    }

    return SplitMemberShare(
      userId: resolvedUserId,
      name: json['name'] ?? (json['user'] is Map ? json['user']['name'] ?? '' : ''),
      email: json['email'] ?? (json['user'] is Map ? json['user']['email'] ?? '' : ''),
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      percentage: (json['percentage'] is num) ? (json['percentage'] as num).toDouble() : 0.0,
      status: json['status'] ?? 'Unpaid',
      proofTid: proof?['transactionId'] ?? proof?['tid'] ?? json['proofTid'],
      proofImageUrl: proof?['imageUrl'] ?? proof?['receiptUrl'] ?? json['proofImageUrl'],
      paymentMethod: proof?['paymentMethod'] ?? json['paymentMethod'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'userId': userId,
      'name': name,
      'email': email,
      'amount': amount,
      'percentage': percentage,
      'status': status,
      'proof': {
        'transactionId': proofTid,
        'imageUrl': proofImageUrl,
        'paymentMethod': paymentMethod,
      },
      'proofTid': proofTid,
      'proofImageUrl': proofImageUrl,
      'paymentMethod': paymentMethod,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitMemberShare &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          amount == other.amount &&
          status == other.status &&
          proofTid == other.proofTid &&
          proofImageUrl == other.proofImageUrl;

  @override
  int get hashCode =>
      userId.hashCode ^
      amount.hashCode ^
      status.hashCode ^
      proofTid.hashCode ^
      proofImageUrl.hashCode;
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

  SplitExpenseModel copyWith({
    String? id,
    String? title,
    double? totalAmount,
    String? category,
    String? paidByUserId,
    String? paidByName,
    String? groupId,
    String? groupName,
    String? splitType,
    DateTime? date,
    String? notes,
    bool? isFullySettled,
    List<SplitMemberShare>? splits,
  }) {
    return SplitExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      category: category ?? this.category,
      paidByUserId: paidByUserId ?? this.paidByUserId,
      paidByName: paidByName ?? this.paidByName,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      splitType: splitType ?? this.splitType,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isFullySettled: isFullySettled ?? this.isFullySettled,
      splits: splits ?? this.splits,
    );
  }

  factory SplitExpenseModel.fromJson(Map<String, dynamic> json) {
    var rawSplits = (json['splits'] ?? json['participants']) as List<dynamic>? ?? [];
    List<SplitMemberShare> parsedSplits = rawSplits
        .map((s) => SplitMemberShare.fromJson(s as Map<String, dynamic>))
        .toList();

    DateTime parsedDate;
    try {
      parsedDate = json['date'] != null ? DateTime.parse(json['date']) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    String uid = '';
    if (json['paidByUserId'] != null && json['paidByUserId'].toString().isNotEmpty) {
      uid = json['paidByUserId'].toString();
    } else if (json['paidBy'] != null) {
      if (json['paidBy'] is String) {
        uid = json['paidBy'];
      } else if (json['paidBy'] is Map) {
        uid = json['paidBy']['_id']?.toString() ?? json['paidBy']['id']?.toString() ?? '';
      }
    }

    String gid = '';
    if (json['groupId'] != null) {
      if (json['groupId'] is String) {
        gid = json['groupId'];
      } else if (json['groupId'] is Map) {
        gid = json['groupId']['_id']?.toString() ?? json['groupId']['id']?.toString() ?? '';
      }
    }

    return SplitExpenseModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Shared Expense',
      totalAmount: (json['totalAmount'] is num) ? (json['totalAmount'] as num).toDouble() : 0.0,
      category: json['category'] ?? 'Food',
      paidByUserId: uid,
      paidByName: json['paidByName'] ?? (json['paidBy'] is Map ? json['paidBy']['name'] ?? '' : ''),
      groupId: gid.isNotEmpty ? gid : null,
      groupName: json['groupName'] ?? (json['groupId'] is Map ? json['groupId']['name'] ?? '' : ''),
      splitType: json['splitType'] ?? 'Equal',
      date: parsedDate,
      notes: json['notes'] ?? '',
      isFullySettled: json['isFullySettled'] ?? false,
      splits: parsedSplits,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'title': title,
      'totalAmount': totalAmount,
      'category': category,
      'paidBy': paidByUserId,
      'paidByUserId': paidByUserId,
      'paidByName': paidByName,
      'groupId': groupId,
      'groupName': groupName,
      'splitType': splitType,
      'date': date.toIso8601String(),
      'notes': notes,
      'isFullySettled': isFullySettled,
      'splits': splits.map((s) => s.toJson()).toList(),
      'participants': splits.map((s) => s.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitExpenseModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
