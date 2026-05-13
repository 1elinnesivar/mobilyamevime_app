import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProductImageView extends StatelessWidget {
  const ProductImageView({
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: imageUrl == null || imageUrl!.isEmpty
            ? const _ProductPlaceholder()
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: fit,
                placeholder: (context, url) => const _ProductPlaceholder(loading: true),
                errorWidget: (context, url, error) => const _ProductPlaceholder(),
              ),
      ),
    );
  }
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111111),
      child: Center(
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : const Icon(
                Icons.image_not_supported_outlined,
                color: Color(0xFF3B4268),
              ),
      ),
    );
  }
}
