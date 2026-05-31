import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';

class UserStatusColumn extends StatefulWidget {
  final String name;
  final VoidCallback onAddStatus;
  final VoidCallback? onViewStatus;
  final bool hasStatus;
  final String? image;

  const UserStatusColumn({
    super.key,
    required this.name,
    required this.onAddStatus,
    required this.onViewStatus,
    required this.image,
    required this.hasStatus,
  });

  @override
  State<UserStatusColumn> createState() => _UserStatusColumnState();
}

class _UserStatusColumnState extends State<UserStatusColumn>
    with TickerProviderStateMixin {
  late AnimationController _tapController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _tapController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.hasStatus && widget.onViewStatus != null) {
      widget.onViewStatus!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onTapDown: (_) => _tapController.forward(),
        onTapUp: (_) {
          _tapController.reverse();
          _handleTap();
        },
        onTapCancel: () => _tapController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPallete.cardBg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.hasStatus
                    ? AppPallete.primaryOrange.withValues(alpha: 0.5)
                    : AppPallete.divider.withValues(alpha: 0.3),
                width: widget.hasStatus ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: widget.image != null
                          ? (widget.image!.startsWith('assets/')
                              ? AssetImage(widget.image!) as ImageProvider
                              : NetworkImage(widget.image!))
                          : null,
                      backgroundColor: AppPallete.cardBg,
                      child: widget.image == null
                          ? const Icon(Icons.person, color: AppPallete.greyText)
                          : null,
                    ),
                    if (widget.hasStatus)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppPallete.primaryOrange,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppPallete.cardBg,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.hasStatus ? 'My Status' : widget.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppPallete.whiteColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            widget.hasStatus
                                ? Icons.visibility
                                : Icons.add_circle_outline,
                            size: 12,
                            color: AppPallete.greyText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.hasStatus
                                ? 'Tap to view'
                                : 'Add to share updates',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppPallete.greyText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildAddButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: widget.onAddStatus,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppPallete.primaryOrange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_a_photo, size: 18, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Add',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}