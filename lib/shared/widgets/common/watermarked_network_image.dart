import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Network image with a centered semi-transparent watermark overlay.
class WatermarkedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double watermarkWidthFactor;

  const WatermarkedNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
    this.watermarkWidthFactor = 0.38,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          fit: fit,
          alignment: alignment,
          placeholder: (_, __) =>
              placeholder ?? const Center(child: CircularProgressIndicator()),
          errorWidget: (_, __, ___) =>
              errorWidget ??
              const Icon(Icons.broken_image_outlined, size: 48),
        ),
        Center(
          child: Opacity(
            opacity: 0.42,
            child: Image.asset(
              'assets/images/watermark_logo.png',
              width: MediaQuery.sizeOf(context).width * watermarkWidthFactor,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}
