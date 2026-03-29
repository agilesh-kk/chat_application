import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserDetailsCard extends StatelessWidget {
  final String email;
  final String bio;
  final DateTime birthDate;
  final IconData? button;
  final VoidCallback? bioUpdate;

  const UserDetailsCard({
    super.key,
    required this.email,
    required this.bio,
    required this.birthDate,
    this.button,
    this.bioUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        //color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          //email
          _buildSection(
            title: "Email",
            value: email,
          ),

          const SizedBox(height: 16),

          //bio
          _buildSection(
            title: "Bio",
            value: bio,
            icon: button,
            onPressed: bioUpdate,
          ),

          const SizedBox(height: 16),

          //birth date
          _buildSection(
            title: "Birthday",
            value: DateFormat('MMM dd, yyyy').format(birthDate),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String value,
    IconData? icon,
    VoidCallback? onPressed,
  }) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            
          ],
        ),
        const SizedBox(width: 40),
        if(icon!=null)
        IconButton(
          icon: Icon(button),
          onPressed: onPressed,
        )
      ],
    );
  }
}