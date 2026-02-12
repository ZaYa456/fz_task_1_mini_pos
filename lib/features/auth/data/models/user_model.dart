import 'package:hive/hive.dart';

part 'user_model.g.dart'; // This file is generated automatically

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late String passwordHash; // Store hashed password, never plain text

  @HiveField(2)
  late DateTime registeredDate;
}