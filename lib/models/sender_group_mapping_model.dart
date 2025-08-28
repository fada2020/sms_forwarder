class SenderGroupMappingModel {
  final int? id;
  final int senderFilterId;
  final int groupId;
  final DateTime createdAt;

  SenderGroupMappingModel({
    this.id,
    required this.senderFilterId,
    required this.groupId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderFilterId': senderFilterId,
      'groupId': groupId,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory SenderGroupMappingModel.fromMap(Map<String, dynamic> map) {
    return SenderGroupMappingModel(
      id: map['id'],
      senderFilterId: map['senderFilterId'] ?? 0,
      groupId: map['groupId'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  SenderGroupMappingModel copyWith({
    int? id,
    int? senderFilterId,
    int? groupId,
    DateTime? createdAt,
  }) {
    return SenderGroupMappingModel(
      id: id ?? this.id,
      senderFilterId: senderFilterId ?? this.senderFilterId,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}