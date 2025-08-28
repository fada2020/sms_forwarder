class GroupMemberModel {
  final int? id;
  final int groupId;
  final int contactId;
  final DateTime addedAt;

  GroupMemberModel({
    this.id,
    required this.groupId,
    required this.contactId,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'contactId': contactId,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }

  factory GroupMemberModel.fromMap(Map<String, dynamic> map) {
    return GroupMemberModel(
      id: map['id'],
      groupId: map['groupId'] ?? 0,
      contactId: map['contactId'] ?? 0,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['addedAt'] ?? 0),
    );
  }

  GroupMemberModel copyWith({
    int? id,
    int? groupId,
    int? contactId,
    DateTime? addedAt,
  }) {
    return GroupMemberModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      contactId: contactId ?? this.contactId,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}