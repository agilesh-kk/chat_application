import 'package:flutter/material.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/services.dart';

class AuthFields extends StatefulWidget {
  final String hinText;
  final TextEditingController textController;
  final bool isObscure;
  final IconData? icon;
  final bool? isSmall;

  const AuthFields({
    super.key,
    required this.hinText,
    required this.textController,
    required this.isObscure,
    this.icon,
    this.isSmall,
  });

  @override
  State<AuthFields> createState() => _AuthFieldsState();
}

class _AuthFieldsState extends State<AuthFields> {
  late bool _isObscured;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.isObscure;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isFocused ? AppPallete.inputBg : AppPallete.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused 
              ? AppPallete.primaryOrange.withValues(alpha: 0.5) 
              : AppPallete.divider.withValues(alpha: 0.3),
          width: _isFocused ? 1.5 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppPallete.primaryOrange.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Focus(
        onFocusChange: (focused) {
          setState(() {
            _isFocused = focused;
          });
        },
        child: TextFormField(
          inputFormatters: widget.isSmall == true
            ? [
                TextInputFormatter.withFunction(
                  (oldValue, newValue) {
                    return newValue.copyWith(
                      text: newValue.text.toLowerCase(),
                      selection: newValue.selection,
                    );
                  },
                ),
              ]
            : null,
          style: const TextStyle(color: AppPallete.whiteColor),
          decoration: InputDecoration(
            hintText: widget.hinText,
            hintStyle: TextStyle(
              color: AppPallete.greyText.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              widget.icon ?? (widget.isObscure ? Icons.lock_outline : Icons.email_outlined),
              color: _isFocused ? AppPallete.primaryOrange : AppPallete.greyText,
              size: 20,
            ),
            suffixIcon: widget.isObscure
                ? IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                      color: _isFocused ? AppPallete.primaryOrange : AppPallete.greyText,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscured = !_isObscured;
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
          controller: widget.textController,
          obscureText: _isObscured,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "${widget.hinText} is empty";
            }
            return null;
          },
        ),
      ),
    );
  }
}