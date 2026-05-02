import 'package:cloud_firestore/cloud_firestore.dart';

class FriendModel {
  final String id;
  final String name;
  final String profilePic;
  final String email;
  final DateTime? birthDate;
  final String? gender;
  final String? bio;

  FriendModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profilePic,
    this.birthDate,
    this.gender,
    this.bio
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'],
      name: json['name'],
      profilePic: json['profilePic'],
      email: json['email'],
      birthDate: json['birthDate'] != null 
        ? (json['birthDate'] as Timestamp).toDate()
        : null,
      gender: json['gender'],
      bio: json['bio']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profilePic': profilePic,
      'email': email,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
      'bio' : bio
    };
  }
}