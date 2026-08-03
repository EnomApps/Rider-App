import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';

/// The square "N + pin" mark, clipped to a rounded tile.
///
/// The source artwork carries its own black backdrop, so the tile is filled
/// with the same black to keep the edges clean in both themes.
///
/// The asset is 1024x1024 and this renders it at ~42dp, so the bitmap is
/// decoded down to the display size via [Image.asset.cacheWidth] rather than
/// handed to the GPU at full resolution. Two reasons:
///
/// * Correctness — a >8x downscale combined with `FilterQuality.medium` takes
///   Impeller's mipmap path, which rendered the tile as solid black on device
///   (Android 16, Vulkan). Decoding at size sidesteps it entirely.
/// * Memory — a 1024x1024 RGBA decode is ~4MB for a 42dp tile.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48, this.radius = 14});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final double devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final int pixels = (size * devicePixelRatio).ceil();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        AppAssets.mark,
        fit: BoxFit.cover,
        cacheWidth: pixels,
        cacheHeight: pixels,
      ),
    );
  }
}
