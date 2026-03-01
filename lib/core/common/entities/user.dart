//core user structure
import 'dart:io';

class User {
  final String id;
  final String name;
  final String email;
  final File? profilePic;
  User({required this.id, required this.name, required this.email, this.profilePic});
}