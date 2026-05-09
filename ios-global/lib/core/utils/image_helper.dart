import 'package:flutter/material.dart';

class AppImages {
  static const String baseAssetUrl = 'assets/images/';

  static ImageProvider imageProvider(String assetName) {
    return AssetImage('$baseAssetUrl$assetName');
  }

  static Widget networkImage(
    String url, {
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Icon(Icons.broken_image_outlined, color: Colors.grey[400]),
          );
        },
      ),
    );
  }
}
