import 'package:cloud_firestore/cloud_firestore.dart';

class FriendModel {
  final String id;
  final String name;
  final String profilePic;
  final String email;
  final DateTime? birthDate;
  final String? gender;
  final String? bio;
  final bool isOnline;
  final DateTime? lastSeen;

  FriendModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profilePic,
    this.birthDate,
    this.gender,
    this.bio,
    this.isOnline = false,
    this.lastSeen,
  });

  bool get isEffectivelyOnline =>
      isOnline && (lastSeen == null ||
      DateTime.now().difference(lastSeen!) < const Duration(seconds: 40));

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
      bio: json['bio'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? (json['lastSeen'] as Timestamp).toDate()
          : null,
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
      'bio' : bio,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }
}