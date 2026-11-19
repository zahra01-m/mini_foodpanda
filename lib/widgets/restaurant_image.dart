import 'package:flutter/material.dart';
import '../core/utils/image_data.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/cuisine_icon.dart';
import '../models/restaurant_model.dart';
import 'shimmer_box.dart';

/// A restaurant's photo, sized by whatever box it is placed in.
///
/// While the photo loads it shows a shimmer, then fades the image in.
/// If the restaurant has no `imageUrl` (or the URL fails to load) it
/// falls back to a warm gradient with a cuisine-appropriate icon, so
/// the UI never shows a broken-image box.
class RestaurantImage extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantImage({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final url = restaurant.imageUrl.trim();
    // A photo bundled with the app (assets/images/...) can live in either field:
    // `imageUrl` wins when set, otherwise `imageAsset` is used.
    final source = url.isNotEmpty ? url : restaurant.imageAsset.trim();
    // Banners are light (cream/white), which glares in dark mode — dim them a bit.
    final dim = Theme.of(context).brightness == Brightness.dark;
    final dimColor = dim ? Colors.black.withValues(alpha: 0.22) : null;
    final dimMode = dim ? BlendMode.darken : null;
    if (isDataImage(source)) {
      final bytes = decodeDataImage(source);
      if (bytes == null) return _Fallback(category: restaurant.category);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        color: dimColor,
        colorBlendMode: dimMode,
        errorBuilder: (context, error, stackTrace) => _Fallback(category: restaurant.category),
      );
    }
    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: 1200,
        color: dimColor,
        colorBlendMode: dimMode,
        errorBuilder: (context, error, stackTrace) => _Fallback(category: restaurant.category),
      );
    }
    if (url.isEmpty) return _Fallback(category: restaurant.category);

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        if (frame == null) return const ShimmerBox(height: double.infinity);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          builder: (context, value, child) => Opacity(opacity: value, child: child),
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) => _Fallback(category: restaurant.category),
    );
  }
}

class _Fallback extends StatelessWidget {
  final String category;
  const _Fallback({required this.category});

  static IconData _iconFor(String category) => cuisineIcon(category);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(_iconFor(category), size: 48, color: Colors.white.withValues(alpha: 0.85)),
      ),
    );
  }
}
