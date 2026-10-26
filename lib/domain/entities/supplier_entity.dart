import 'package:equatable/equatable.dart';

class SupplierEntity extends Equatable {
  final String? id;
  final String name;
  final String? phone;
  final String? address;
  final String? note;
  final String? createdAt;
  final String? updatedAt;

  const SupplierEntity({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  SupplierEntity copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? note,
    String? createdAt,
    String? updatedAt,
  }) {
    return SupplierEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, address, note, createdAt, updatedAt];
}
