import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';

class CreateRoomBottomSheet extends StatefulWidget {
  final void Function(String name) onCreated;

  const CreateRoomBottomSheet({super.key, required this.onCreated});

  @override
  State<CreateRoomBottomSheet> createState() => _CreateRoomBottomSheetState();
}

class _CreateRoomBottomSheetState extends State<CreateRoomBottomSheet> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppPallete.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPallete.greyText,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Create Watch Room',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Room name (e.g. Movie Night)',
                hintStyle:
                    TextStyle(color: AppPallete.greyText.withValues(alpha: 0.5)),
                filled: true,
                fillColor: AppPallete.inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppPallete.primaryOrange, width: 1.5),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a room name' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPallete.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onCreated(_nameController.text.trim());
                  Navigator.pop(context);
                }
              },
              child: const Text('Create Room', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
