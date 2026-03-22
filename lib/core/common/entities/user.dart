//user structure

class User {
  final String id;
  final String name;
  final String email;
  final String? profilePic;
  final List<String>? friends;
  final DateTime birthDate;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.birthDate,
    this.profilePic,
    this.friends,
  });

  @override
  String toString() {
    // TODO: implement toString
    return "id : $id\nname: $name\nemail: $email";
  }
}
