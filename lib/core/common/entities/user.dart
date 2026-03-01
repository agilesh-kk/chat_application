//user structure

class User {
  final String id;
  final String name;
  final String email;
  final String? profilePic;
  
  User({required this.id, required this.name, required this.email, this.profilePic});

  @override
  String toString() {
    // TODO: implement toString
    return "id : $id\nname: $name\nemail: $email";
  }
}