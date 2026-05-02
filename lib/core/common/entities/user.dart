//user structure

class User {
  final String id;
  final String name;
  final String email;
  final DateTime birthDate;
  final String gender;
  final String? profilePic;
  final List<String>? friends;
  final String? bio;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.birthDate,
    required this.gender,
    this.profilePic,
    this.friends,
    this.bio,
  });

  @override
  String toString() {
    // TODO: implement toString
    return "id : $id\nname: $name\nemail: $email";
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePic,
    List<String>? friends,
    DateTime? birthDate,
    String? bio,
    String? gender
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePic: profilePic ?? this.profilePic,
      friends: friends ?? this.friends,
      birthDate: birthDate ?? this.birthDate,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
    );
  }
}
