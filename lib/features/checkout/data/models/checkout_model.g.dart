// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CheckoutModelAdapter extends TypeAdapter<CheckoutModel> {
  @override
  final int typeId = 2;

  @override
  CheckoutModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CheckoutModel()
      ..id = fields[0] as int
      ..totalAmount = fields[1] as double
      ..date = fields[2] as DateTime
      ..items = (fields[3] as List).cast<CheckoutItemModel>()
      ..status = fields[4] as String;
  }

  @override
  void write(BinaryWriter writer, CheckoutModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.totalAmount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckoutModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
