import '../../domain/entities/supplier_entity.dart';

class SupplierModel {
  String id;
  String name;
  String? phone;
  String? address;
  String? note;
  String? createdAt;
  String? updatedAt;

  SupplierModel({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      address: json['address'],
      note: json['note'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'note': note,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory SupplierModel.fromEntity(SupplierEntity entity) {
    return SupplierModel(
      id: entity.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: entity.name,
      phone: entity.phone,
      address: entity.address,
      note: entity.note,
      createdAt: entity.createdAt ?? DateTime.now().toIso8601String(),
      updatedAt: entity.updatedAt ?? DateTime.now().toIso8601String(),
    );
  }

  SupplierEntity toEntity() {
    return SupplierEntity(
      id: id,
      name: name,
      phone: phone,
      address: address,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
