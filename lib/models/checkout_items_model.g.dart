// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_items_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CheckoutItemAdapter extends TypeAdapter<CheckoutItem> {
  @override
  final int typeId = 3;

  @override
  CheckoutItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CheckoutItem()
      ..itemId = fields[0] as int
      ..itemName = fields[1] as String
      ..quantity = fields[2] as int
      ..priceAtSale = fields[3] as double;
  }

  @override
  void write(BinaryWriter writer, CheckoutItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.itemId)
      ..writeByte(1)
      ..write(obj.itemName)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.priceAtSale);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckoutItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
