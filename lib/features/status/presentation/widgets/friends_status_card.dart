import 'dart:io';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/moments_ago.dart';
import 'package:chat_application/core/utils/profile_image_provider.dart';
import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:chat_application/features/status/presentation/widgets/status_ring_painter.dart';
import 'package:flutter/material.dart';

class FriendsStatusCard extends StatefulWidget {
  final List<Status> statuses;
  final VoidCallback onstatusTap;

  const FriendsStatusCard({
    super.key,
    required this.statuses,
    required this.onstatusTap,
  });

  @override
  State<FriendsStatusCard> createState() => _FriendsStatusCardState();
}

class _FriendsStatusCardState extends State<FriendsStatusCard>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
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

  int get _totalStatuses => widget.statuses.length;
  int get _viewedStatuses =>
      widget.statuses.where((s) => s.isViewed).length;

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onTapDown: (_) => _tapController.forward(),
        onTapUp: (_) {
          _tapController.reverse();
          widget.onstatusTap();
        },
        onTapCancel: () => _tapController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildProfileAvatar(),
                const SizedBox(width: 12),
                Expanded(child: _buildCard()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final first = widget.statuses.first;
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(56, 56),
            painter: StatusRingPainter(
              totalStatuses: _totalStatuses,
              viewedStatuses: _viewedStatuses,
            ),
          ),
          CircleAvatar(
            radius: 24,
            backgroundImage: displayImage(first),
            backgroundColor: AppPallete.cardBg,
            child: first.profilepic.isEmpty
                ? const Icon(Icons.person, color: AppPallete.greyText, size: 22)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppPallete.cardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPallete.divider.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          _buildStatusInfo(),
          _buildStatusPreview(),
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    final latest = widget.statuses.first;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              latest.userName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppPallete.whiteColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              MomentsAgo.calculateMomentsAgo(
                widget.statuses.last.createdAt.toIso8601String(),
              ),
              style: TextStyle(
                fontSize: 12,
                color: AppPallete.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPreview() {
    return SizedBox(
      width: 72,
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
        child: _buildStatusImage(),
      ),
    );
  }

  Widget _buildStatusImage() {
    final status = widget.statuses.first;
    if (status.localPath != null) {
      return Image.file(
        File(status.localPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildNetworkImage(),
      );
    }
    return _buildNetworkImage();
  }

  Widget _buildNetworkImage() {
    final status = widget.statuses.first;
    return Image.network(
      status.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppPallete.cardBg,
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppPallete.primaryOrange,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: AppPallete.cardBg,
        child: const Icon(
          Icons.image,
          color: AppPallete.greyText,
          size: 20,
        ),
      ),
    );
  }

  ImageProvider displayImage(Status s) {
    if (s.profilepic.isNotEmpty) {
      return profileImageProvider(s.profilepic) ?? AssetImage('');
    }
    if (s.localPath != null) {
      return FileImage(File(s.localPath!));
    }
    return NetworkImage(s.imageUrl);
  }
}
