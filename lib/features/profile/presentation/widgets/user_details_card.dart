import 'package:chat_application/features/profile/presentation/bloc/bio/bio_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class UserDetailsCard extends StatefulWidget {
  final String email;
  final String bio;
  final DateTime birthDate;
  final String gender;
  final String userId;

  /// if null → read only
  final VoidCallback? onEditBio;

  const UserDetailsCard({
    super.key,
    required this.email,
    required this.bio,
    required this.birthDate,
    required this.gender,
    required this.userId,
    this.onEditBio,
  });

  @override
  State<UserDetailsCard> createState() => _UserDetailsCardState();
}

class _UserDetailsCardState extends State<UserDetailsCard> {
  bool isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.bio);
  }

  @override
  void didUpdateWidget(covariant UserDetailsCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// keep controller in sync when bloc updates UI
    if (oldWidget.bio != widget.bio) {
      _controller.text = widget.bio;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    if (widget.onEditBio == null) return;

    setState(() {
      isEditing = true;
    });
  }

  void _saveBio() {
    final newBio = _controller.text.trim();

    context.read<BioBloc>().add(
      BioUpdate(
        userId: widget.userId,
        bio: newBio,
      ),
    );

    setState(() {
      isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditable = widget.onEditBio != null;

    return PopScope(
      canPop: !isEditing,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (isEditing) {
          setState(() {
            isEditing = false;
            _controller.text = widget.bio;
          });

          /// close keyboard
          FocusScope.of(context).unfocus();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
      
            //EMAIL
            _buildNormalSection(
              title: "Email",
              value: widget.email,
            ),
      
            const SizedBox(height: 16),
      
            //BIO 
            _buildBioSection(isEditable),
      
            const SizedBox(height: 16),
      
            //BIRTHDATE
            _buildNormalSection(
              title: "Birthday",
              value: DateFormat('MMM dd, yyyy').format(widget.birthDate),
            ),
      
            const SizedBox(height: 16),
      
            //GENDER
            _buildNormalSection(
              title: "Gender",
              value: widget.gender,
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- NORMAL SECTION ----------------
  Widget _buildNormalSection({
    required String title,
    required String value,
  }) {
    return Column(
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
    );
  }

  /// ---------------- BIO SECTION ----------------
  Widget _buildBioSection(bool isEditable) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// TEXT / TEXTFIELD
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              if (isEditing)
                TextField(
                  controller: _controller,
                  maxLines: null,
                  autofocus: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _saveBio(),
                )
              else
                Text(
                  widget.bio,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

              const SizedBox(height: 4),

              const Text(
                "Bio",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        /// ICON (ONLY IF EDITABLE)
        if (isEditable)
          IconButton(
            icon: Icon(
              isEditing ? Icons.check : Icons.edit,
              size: 20,
            ),
            onPressed: isEditing ? _saveBio : _startEditing,
          ),
      ],
    );
  }
}