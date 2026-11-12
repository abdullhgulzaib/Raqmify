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

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['user'] is String ? json['user'] : (json['user']?['_id'] ?? ''),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'Member',
      joinedAt: json['joinedAt'] != null ? DateTime.tryParse(json['joinedAt']) : null,
    );
  }
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

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    var rawMembers = json['members'] as List<dynamic>? ?? [];
    List<GroupMember> parsedMembers = rawMembers
        .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
        .toList();

    return GroupModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Shared Group',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Hostel',
      icon: json['icon'] ?? 'home',
      createdBy: json['createdBy'] is String ? json['createdBy'] : (json['createdBy']?['_id'] ?? ''),
      inviteCode: json['inviteCode'] ?? '',
      members: parsedMembers,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) ?? DateTime.now() : DateTime.now(),
    );
  }
}
