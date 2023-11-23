// database.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

abstract class Transaction {
  late double amount;
  late DateTime date;
  late TimeOfDay time;
  late String? category;
}

class PeraIn extends Transaction {
  PeraIn({
    required double amount,
    required DateTime date,
    required TimeOfDay time,
    required String? category,
  }) {
    this.amount = amount;
    this.date = date;
    this.time = time;
    this.category = category;
  }
}

class PeraOut extends Transaction {
  PeraOut({
    required double amount,
    required DateTime date,
    required TimeOfDay time,
    required String? category,
  }) {
    this.amount = amount;
    this.date = date;
    this.time = time;
    this.category = category;
  }
}

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 0;

  @override
  Transaction read(BinaryReader reader) {
    final typeId = reader.readByte(); // Read typeId here

    switch (typeId) {
      case 0:
        return PeraIn(
          amount: reader.read(),
          date: DateTime.parse(reader.read()),
          time: _readTimeOfDay(reader),
          category: reader.read(),
        );

      case 1:
        return PeraOut(
          amount: reader.read(),
          date: DateTime.parse(reader.read()),
          time: _readTimeOfDay(reader),
          category: reader.read(),
        );
      default:
        throw Exception("Unknown type ID: $typeId");
    }
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    if (obj is PeraIn) {
      writer.writeByte(0);
      writer.write(obj.amount);
      writer.write(obj.date.toIso8601String());
      _writeTimeOfDay(writer, obj.time);
      writer.write(obj.category);
    } else if (obj is PeraOut) {
      writer.writeByte(1);
      writer.write(obj.amount);
      writer.write(obj.date.toIso8601String());
      _writeTimeOfDay(writer, obj.time);
      writer.write(obj.category);
    } else {
      throw Exception("Unknown transaction type: ${obj.runtimeType}");
    }
  }

  // Helper method to read TimeOfDay
  void _writeTimeOfDay(BinaryWriter writer, TimeOfDay time) {
    if (time != null) {
      writer.writeByte(time.hour);
      writer.writeByte(time.minute);
    } else {
      writer.writeByte(0); // write 0 if TimeOfDay is null
      writer.writeByte(0); // write 0 if TimeOfDay is null
    }
  }

  // Helper method to write TimeOfDay
  TimeOfDay _readTimeOfDay(BinaryReader reader) {
    final hour = reader.readByte();
    final minute = reader.readByte();
    return TimeOfDay(hour: hour, minute: minute);
  }
}
