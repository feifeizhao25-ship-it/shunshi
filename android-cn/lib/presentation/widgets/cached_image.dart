import 'package:flutter/material.dart';

/// 图片组件 - 带缓存和占位图
class CachedImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  
  const CachedImage({
    super.key,
    this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });
  
  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _buildPlaceholder();
    }
    
    return Image.network(
      url!,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _buildPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildError();
      },
    );
  }
  
  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
  
  Widget _buildError() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}

/// 头像组件
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final Color? backgroundColor;
  
  const UserAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
    this.backgroundColor,
  });
  
  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedImage(
          url: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    
    // 使用名字首字母
    final initial = name?.isNotEmpty == true ? name![0].toUpperCase() : '?';
    
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? Colors.green[100],
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.green[700],
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
