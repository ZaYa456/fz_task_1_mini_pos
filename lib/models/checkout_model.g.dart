// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CheckoutAdapter extends TypeAdapter<Checkout> {
  @override
  final int typeId = 2;

  @override
  Checkout read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Checkout()
      ..id = fields[0] as int
      ..totalAmount = fields[1] as double
      ..date = fields[2] as DateTime
      ..items = (fields[3] as List).cast<CheckoutItem>();
  }

  @override
  void write(BinaryWriter writer, Checkout obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.totalAmount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.items);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckoutAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
