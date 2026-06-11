import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/profile/presentation/bloc/bio/bio_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserDetailsCard extends StatefulWidget {
  final String? bio;
  final String userId;

  /// if null → read only
  final VoidCallback? onEditBio;

  const UserDetailsCard({
    super.key,
    this.bio,
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
      _controller.text = widget.bio ?? '';
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
            _controller.text = widget.bio ?? '';
          });

          /// close keyboard
          FocusScope.of(context).unfocus();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppPallete.cardBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppPallete.divider.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //BIO 
            _buildBioSection(isEditable),
          ],
        ),
      ),
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
                  style: TextStyle(color: AppPallete.whiteColor),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppPallete.inputBg,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppPallete.primaryOrange),
                    ),
                  ),
                  onSubmitted: (_) => _saveBio(),
                )
              else
                Text(
                  (widget.bio == null || widget.bio!.isEmpty) 
                    ? "No bio yet" 
                    : widget.bio!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: (widget.bio == null || widget.bio!.isEmpty) 
                        ? AppPallete.greyText 
                        : AppPallete.whiteColor,
                  ),
                ),

              const SizedBox(height: 6),

              Text(
                "Bio",
                style: TextStyle(
                  fontSize: 14,
                  color: AppPallete.greyText,
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
              size: 24,
              color: AppPallete.primaryOrange,
            ),
            onPressed: isEditing ? _saveBio : _startEditing,
          ),
      ],
    );
  }
}