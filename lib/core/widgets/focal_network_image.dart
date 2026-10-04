import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FocalNetworkImage extends StatelessWidget {
  final String imageUrl;
  final Alignment alignment;
  final BoxFit fit;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final Widget Function(BuildContext, String)? placeholder;
  final double? width;
  final double? height;

  const FocalNetworkImage({
    super.key,
    required this.imageUrl,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.placeholder,
    this.width,
    this.height,
  });
 
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      alignment: alignment,
      width: width,
      height: height,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: placeholder,
      errorWidget: errorWidget ?? (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

