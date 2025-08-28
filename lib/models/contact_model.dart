class ContactModel {
  final int? id;
  final String name;
  final String phoneNumber;
  final bool isActive;

  ContactModel({
    this.id,
    required this.name,
    required this.phoneNumber,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'],
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      isActive: map['isActive'] == 1,
    );
  }

  ContactModel copyWith({
    int? id,
    String? name,
    String? phoneNumber,
    bool? isActive,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isActive: isActive ?? this.isActive,
    );
  }
}