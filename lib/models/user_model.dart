import '../core/utils/id_extractor.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final String phone;
  final String? easypaisa;
  final String? jazzcash;
  final String? bankName;
  final String? accountNumber;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar = '',
    this.phone = '',
    this.easypaisa,
    this.jazzcash,
    this.bankName,
    this.accountNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final payment = json['paymentDetails'] as Map<String, dynamic>?;
    final resolvedId = extractId(json['_id']).isNotEmpty ? extractId(json['_id']) : extractId(json['id']);
    return UserModel(
      id: resolvedId,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? '',
      phone: json['phone'] ?? '',
      easypaisa: payment?['easypaisa'] as String?,
      jazzcash: payment?['jazzcash'] as String?,
      bankName: payment?['bankName'] as String?,
      accountNumber: payment?['accountNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'phone': phone,
      'paymentDetails': {
        'easypaisa': easypaisa ?? '',
        'jazzcash': jazzcash ?? '',
        'bankName': bankName ?? '',
        'accountNumber': accountNumber ?? '',
      },
    };
  }
}
