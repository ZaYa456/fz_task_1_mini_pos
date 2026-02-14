/// Domain entity representing a user in the system.
/// This is separate from the data model to maintain clean architecture.
class User {
  final String id;
  final String username;
  final String name;
  final DateTime registeredDate;

  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.registeredDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username;

  @override
  int get hashCode => id.hashCode ^ username.hashCode;
}
