import '../core/utils/id_extractor.dart';

class GroupMember {
  final String userId;
  final String name;
  final String email;
  final String role;
  final DateTime? joinedAt;

  GroupMember({
    required this.userId,
    required this.name,
    required this.email,
    this.role = 'Member',
    this.joinedAt,
  });

  GroupMember copyWith({
    String? userId,
    String? name,
    String? email,
    String? role,
    DateTime? joinedAt,
  }) {
    return GroupMember(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final resolvedUserId = extractId(json['user']).isNotEmpty
        ? extractId(json['user'])
        : (extractId(json['userId']).isNotEmpty
            ? extractId(json['userId'])
            : extractId(json['_id']));

    return GroupMember(
      userId: resolvedUserId,
      name: (json['name'] ?? (json['user'] is Map ? json['user']['name'] : ''))?.toString() ?? '',
      email: (json['email'] ?? (json['user'] is Map ? json['user']['email'] : ''))?.toString() ?? '',
      role: json['role'] ?? 'Member',
      joinedAt: json['joinedAt'] != null ? DateTime.tryParse(json['joinedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'name': name,
      'email': email,
      'role': role,
      'joinedAt': joinedAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupMember &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String icon;
  final String createdBy;
  final String inviteCode;
  final List<GroupMember> members;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    this.description = '',
    this.category = 'Hostel',
    this.icon = 'home',
    required this.createdBy,
    required this.inviteCode,
    required this.members,
    required this.createdAt,
  });

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? icon,
    String? createdBy,
    String? inviteCode,
    List<GroupMember>? members,
    DateTime? createdAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      createdBy: createdBy ?? this.createdBy,
      inviteCode: inviteCode ?? this.inviteCode,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    var rawMembers = json['members'] as List<dynamic>? ?? [];
    List<GroupMember> parsedMembers = rawMembers
        .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
        .toList();

    return GroupModel(
      id: extractId(json['_id']).isNotEmpty ? extractId(json['_id']) : extractId(json['id']),
      name: json['name'] ?? 'Shared Group',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Hostel',
      icon: json['icon'] ?? 'home',
      createdBy: extractId(json['createdBy']),
      inviteCode: json['inviteCode'] ?? '',
      members: parsedMembers,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'icon': icon,
      'createdBy': createdBy,
      'inviteCode': inviteCode,
      'members': members.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
