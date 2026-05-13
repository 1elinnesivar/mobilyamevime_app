import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

const _imgProxy = 'https://mobilyamevime-app.vercel.app/api/img?url=';

String _resolveUrl(String url) {
  if (!kIsWeb) return url;
  return '$_imgProxy${Uri.encodeComponent(url)}';
}

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
    final resolved = (imageUrl == null || imageUrl!.isEmpty)
        ? null
        : _resolveUrl(imageUrl!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: resolved == null
            ? const _ProductPlaceholder()
            : CachedNetworkImage(
                imageUrl: resolved,
                fit: fit,
                placeholder: (context, url) =>
                    const _ProductPlaceholder(loading: true),
                errorWidget: (context, url, error) =>
                    const _ProductPlaceholder(),
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
