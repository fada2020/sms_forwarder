class SenderFilterModel {
  final int? id;
  final String phoneNumber;
  final String displayName;
  final bool isActive;

  SenderFilterModel({
    this.id,
    required this.phoneNumber,
    required this.displayName,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory SenderFilterModel.fromMap(Map<String, dynamic> map) {
    return SenderFilterModel(
      id: map['id'],
      phoneNumber: map['phoneNumber'] ?? '',
      displayName: map['displayName'] ?? '',
      isActive: map['isActive'] == 1,
    );
  }

  SenderFilterModel copyWith({
    int? id,
    String? phoneNumber,
    String? displayName,
    bool? isActive,
  }) {
    return SenderFilterModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      isActive: isActive ?? this.isActive,
    );
  }
}