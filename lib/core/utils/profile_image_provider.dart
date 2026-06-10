import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

ImageProvider? profileImageProvider(String? pfp) {
  if (pfp == null || pfp.isEmpty) return null;
  if (pfp.toLowerCase() == "not found") return null;
  if (pfp.startsWith('assets/')) return AssetImage(pfp);
  return CachedNetworkImageProvider(pfp);
}
