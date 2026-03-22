import 'package:chat_application/core/common/entities/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.birthDate,
    super.profilePic,
    super.friends,
  });

  factory UserModel.fromJson(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ??
          map['raw_user_meta_data']?['name'] ??
          map['user_metadata']?['name'] ??
          '',
      email: map['email'] ?? '',
      profilePic: map['profilePic'],
      friends: map['friends'] != null
          ? List<String>.from(map['friends'])
          : [],
      birthDate: map['birthDate'] is Timestamp
        ? (map['birthDate'] as Timestamp).toDate()
        : map['birthDate'] is DateTime
            ? map['birthDate']
            : DateTime(2000, 1, 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profilePic': profilePic,
      'friends':friends,
      'birthDate': Timestamp.fromDate(birthDate),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePic,
    List<String>? friends,
    DateTime? birthDate,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePic: profilePic ?? this.profilePic,
      friends: friends ?? this.friends,
      birthDate: birthDate ?? this.birthDate,
    );
  }
}
