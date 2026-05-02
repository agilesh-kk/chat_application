import 'package:flutter/material.dart';
import 'package:chat_application/core/theme/app_pallette.dart';

class AuthDropdownSelector extends StatefulWidget {
  final List<String> items;
  final String hintText;
  final Function(String?) onChanged;
  final String? selectedValue;

  const AuthDropdownSelector({
    super.key,
    required this.items,
    required this.hintText,
    required this.onChanged,
    required this.selectedValue,
  });

  @override
  State<AuthDropdownSelector> createState() => _AuthDropdownSelectorState();
}

class _AuthDropdownSelectorState extends State<AuthDropdownSelector> with SingleTickerProviderStateMixin {
  bool _isFocused = false;
  late AnimationController _animationController;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _iconRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
        if (focused) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      },
      child: AnimatedContainer(
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
        child: DropdownButtonFormField<String>(
          value: widget.selectedValue,
          hint: Text(
            widget.hintText,
            style: TextStyle(
              color: AppPallete.greyText.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          icon: RotationTransition(
            turns: _iconRotation,
            child: Icon(
              Icons.arrow_drop_down,
              color: _isFocused ? AppPallete.primaryOrange : AppPallete.greyText,
            ),
          ),
          dropdownColor: AppPallete.cardBg,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.wc_outlined,
              color: _isFocused ? AppPallete.primaryOrange : AppPallete.greyText,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
          items: widget.items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(color: AppPallete.whiteColor),
              ),
            );
          }).toList(),
          onChanged: (value) {
            widget.onChanged(value);
          },
          onTap: () {
            setState(() {
              _isFocused = true;
            });
            _animationController.forward();
          },
          validator: (value) {
            if (value == null) {
              return "Please select ${widget.hintText}";
            }
            return null;
          },
        ),
      ),
    );
  }
}
