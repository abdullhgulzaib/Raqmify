import '../core/utils/id_extractor.dart';

class RecipientPaymentDetails {
  final String phone;
  final String easypaisa;
  final String jazzcash;
  final String bankName;
  final String accountNumber;

  const RecipientPaymentDetails({
    this.phone = '',
    this.easypaisa = '',
    this.jazzcash = '',
    this.bankName = '',
    this.accountNumber = '',
  });

  factory RecipientPaymentDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RecipientPaymentDetails();
    return RecipientPaymentDetails(
      phone: json['phone']?.toString().trim() ?? '',
      easypaisa: json['easypaisa']?.toString().trim() ?? '',
      jazzcash: json['jazzcash']?.toString().trim() ?? '',
      bankName: json['bankName']?.toString().trim() ?? '',
      accountNumber: json['accountNumber']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'easypaisa': easypaisa,
        'jazzcash': jazzcash,
        'bankName': bankName,
        'accountNumber': accountNumber,
      };
}

class NetDebtBreakdownItem {
  final String expenseId;
  final String title;
  final DateTime? date;
  final String category;
  final double amount;
  final String status;

  const NetDebtBreakdownItem({
    required this.expenseId,
    required this.title,
    this.date,
    required this.category,
    required this.amount,
    required this.status,
  });

  factory NetDebtBreakdownItem.fromJson(Map<String, dynamic> json) {
    return NetDebtBreakdownItem(
      expenseId: extractId(json['expenseId'] ?? json['_id']),
      title: json['title']?.toString() ?? 'Expense',
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      category: json['category']?.toString() ?? 'Food',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'Unpaid',
    );
  }

  Map<String, dynamic> toJson() => {
        'expenseId': expenseId,
        'title': title,
        'date': date?.toIso8601String(),
        'category': category,
        'amount': amount,
        'status': status,
      };
}

class NetSettlementModel {
  final String fromUserId;
  final String fromUser;
  final String toUserId;
  final String toUser;
  final double amount;
  final List<NetDebtBreakdownItem> breakdown;
  final bool hasPendingSettlement;
  final String? pendingSettlementId;
  final double? pendingSettlementAmount;
  final RecipientPaymentDetails recipientPaymentDetails;

  const NetSettlementModel({
    required this.fromUserId,
    required this.fromUser,
    required this.toUserId,
    required this.toUser,
    required this.amount,
    this.breakdown = const [],
    this.hasPendingSettlement = false,
    this.pendingSettlementId,
    this.pendingSettlementAmount,
    this.recipientPaymentDetails = const RecipientPaymentDetails(),
  });

  factory NetSettlementModel.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['breakdown'] as List? ?? [];
    return NetSettlementModel(
      fromUserId: extractId(json['fromUserId'] ?? json['fromUser']),
      fromUser: json['fromUser'] is String
          ? json['fromUser'].toString()
          : (json['fromUserName']?.toString() ?? 'Roommate'),
      toUserId: extractId(json['toUserId'] ?? json['toUser']),
      toUser: json['toUser'] is String
          ? json['toUser'].toString()
          : (json['toUserName']?.toString() ?? 'Roommate'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      breakdown: rawBreakdown
          .whereType<Map<String, dynamic>>()
          .map((item) => NetDebtBreakdownItem.fromJson(item))
          .toList(),
      hasPendingSettlement: json['hasPendingSettlement'] == true,
      pendingSettlementId: json['pendingSettlementId'] != null
          ? extractId(json['pendingSettlementId'])
          : null,
      pendingSettlementAmount:
          (json['pendingSettlementAmount'] as num?)?.toDouble(),
      recipientPaymentDetails: RecipientPaymentDetails.fromJson(
        json['recipientPaymentDetails'] as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'fromUserId': fromUserId,
        'fromUser': fromUser,
        'toUserId': toUserId,
        'toUser': toUser,
        'amount': amount,
        'breakdown': breakdown.map((e) => e.toJson()).toList(),
        'hasPendingSettlement': hasPendingSettlement,
        'pendingSettlementId': pendingSettlementId,
        'pendingSettlementAmount': pendingSettlementAmount,
        'recipientPaymentDetails': recipientPaymentDetails.toJson(),
      };
}

class SettlementProofModel {
  final String method;
  final String transactionId;
  final String imageUrl;
  final String senderNote;
  final String paymentDate;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final String? rejectionReason;

  const SettlementProofModel({
    this.method = 'Easypaisa',
    this.transactionId = '',
    this.imageUrl = '',
    this.senderNote = '',
    this.paymentDate = '',
    this.submittedAt,
    this.verifiedAt,
    this.rejectionReason,
  });

  factory SettlementProofModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SettlementProofModel();
    return SettlementProofModel(
      method: json['method']?.toString() ?? 'Easypaisa',
      transactionId: (json['transactionId'] ?? json['proofTid'])?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      senderNote: json['senderNote']?.toString() ?? '',
      paymentDate: json['paymentDate']?.toString() ?? '',
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : null,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'].toString())
          : null,
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'method': method,
        'transactionId': transactionId,
        'imageUrl': imageUrl,
        'senderNote': senderNote,
        'paymentDate': paymentDate,
        'submittedAt': submittedAt?.toIso8601String(),
        'verifiedAt': verifiedAt?.toIso8601String(),
        'rejectionReason': rejectionReason,
      };
}

class SettlementCoveredExpense {
  final String expenseId;
  final String? splitUserId;
  final String? direction;
  final String title;
  final double amount;

  const SettlementCoveredExpense({
    required this.expenseId,
    this.splitUserId,
    this.direction,
    required this.title,
    required this.amount,
  });

  factory SettlementCoveredExpense.fromJson(Map<String, dynamic> json) {
    return SettlementCoveredExpense(
      expenseId: extractId(json['expenseId'] ?? json['_id']),
      splitUserId: json['splitUserId'] != null ? extractId(json['splitUserId']) : null,
      direction: json['direction']?.toString(),
      title: json['title']?.toString() ?? 'Expense',
      amount: ((json['amount'] ?? json['shareAmount']) as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'expenseId': expenseId,
        'splitUserId': splitUserId,
        'direction': direction,
        'title': title,
        'amount': amount,
      };
}

class SettlementModel {
  final String id;
  final String fromUser;
  final String fromUserName;
  final String toUser;
  final String toUserName;
  final String? groupId;
  final String groupName;
  final double amount;
  final String status;
  final SettlementProofModel? proof;
  final List<SettlementCoveredExpense> coveredExpenses;
  final DateTime? createdAt;

  const SettlementModel({
    required this.id,
    required this.fromUser,
    this.fromUserName = '',
    required this.toUser,
    this.toUserName = '',
    this.groupId,
    this.groupName = '',
    required this.amount,
    this.status = 'UnderReview',
    this.proof,
    this.coveredExpenses = const [],
    this.createdAt,
  });

  factory SettlementModel.fromJson(Map<String, dynamic> json) {
    final rawCovered = json['coveredExpenses'] as List? ?? [];
    return SettlementModel(
      id: extractId(json['_id'] ?? json['id']),
      fromUser: extractId(json['fromUser']),
      fromUserName: json['fromUserName']?.toString() ?? '',
      toUser: extractId(json['toUser']),
      toUserName: json['toUserName']?.toString() ?? '',
      groupId: json['groupId'] != null ? extractId(json['groupId']) : null,
      groupName: json['groupName']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'UnderReview',
      proof: json['proof'] != null
          ? SettlementProofModel.fromJson(json['proof'] as Map<String, dynamic>?)
          : null,
      coveredExpenses: rawCovered
          .whereType<Map<String, dynamic>>()
          .map((item) => SettlementCoveredExpense.fromJson(item))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromUser': fromUser,
        'fromUserName': fromUserName,
        'toUser': toUser,
        'toUserName': toUserName,
        'groupId': groupId,
        'groupName': groupName,
        'amount': amount,
        'status': status,
        'proof': proof?.toJson(),
        'coveredExpenses': coveredExpenses.map((e) => e.toJson()).toList(),
        'createdAt': createdAt?.toIso8601String(),
      };
}
