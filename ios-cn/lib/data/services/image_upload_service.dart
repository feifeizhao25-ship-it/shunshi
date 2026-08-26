// 图片上传服务
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../storage/storage_manager.dart';

/// 图片上传状态
enum ImageUploadState {
  idle,
  selecting,
  uploading,
  uploaded,
  error,
}

/// 图片上传结果
class UploadedImage {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final int width;
  final int height;
  
  const UploadedImage({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.width,
    required this.height,
  });
}

/// 图片上传服务
class ImageUploadService {
  final ImagePicker _picker = ImagePicker();
  
  /// 选择图片
  Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
  
  /// 选择多张图片
  Future<List<File>> pickMultipleImages({
    int maxImages = 9,
  }) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      
      return pickedFiles
          .take(maxImages)
          .map((xf) => File(xf.path))
          .toList();
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return [];
    }
  }
  
  /// 拍照
  Future<File?> takePhoto({
    int? maxWidth,
    int? maxHeight,
  }) async {
    return pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }
  
  /// 上传图片到服务器
  Future<UploadedImage?> uploadImage(
    File imageFile, {
    String? folder,
    Function(double)? onProgress,
  }) async {
    try {
      final id = const Uuid().v4();
      
      // 调用后端真实上传 API
      final dio = Dio();
      final token = _getToken();
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        'prefix': folder ?? 'images',
      });
      
      final options = Options(
        headers: {
          'Content-Type': 'multipart/form-data',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      final baseUrl = _getBaseUrl();
      final response = await dio.post(
        '$baseUrl/api/v1/upload/image',
        data: formData,
        options: options,
        onSendProgress: (sent, total) {
          if (total > 0) {
            onProgress?.call(sent / total);
          }
        },
      );
      
      if (response.data is Map && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final url = data['url'] as String;
        
        return UploadedImage(
          id: id,
          url: url,
          thumbnailUrl: url, // 后端暂不生成缩略图，用原图
          width: 1920,
          height: 1080,
        );
      } else {
        debugPrint('Upload failed: ${response.data}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
  
  // 获取 API Base URL
  static String _getBaseUrl() {
    // 从环境或默认配置获取
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.shunshi.app',
    );
  }
  
  // 获取存储的 Token
  static String? _getToken() {
    return StorageManager.user.getToken();
  }
  
  /// 上传多张图片
  Future<List<UploadedImage>> uploadMultipleImages(
    List<File> imageFiles, {
    String? folder,
    Function(double)? onProgress,
  }) async {
    final results = <UploadedImage>[];
    
    for (var i = 0; i < imageFiles.length; i++) {
      final result = await uploadImage(
        imageFiles[i],
        folder: folder,
        onProgress: (progress) {
          // 计算总体进度
          final totalProgress = (i + progress) / imageFiles.length;
          onProgress?.call(totalProgress);
        },
      );
      
      if (result != null) {
        results.add(result);
      }
    }
    
    return results;
  }
}

/// 图片上传 Provider
final imageUploadProvider = StateNotifierProvider<ImageUploadNotifier, ImageUploadState>((ref) {
  return ImageUploadNotifier();
});

class ImageUploadNotifier extends StateNotifier<ImageUploadState> {
  ImageUploadNotifier() : super(ImageUploadState.idle);
  
  final ImageUploadService _service = ImageUploadService();
  
  List<File> _selectedImages = [];
  List<UploadedImage> _uploadedImages = [];
  double _progress = 0;
  
  List<File> get selectedImages => _selectedImages;
  List<UploadedImage> get uploadedImages => _uploadedImages;
  double get progress => _progress;
  
  /// 选择图片
  Future<void> pickImages({int maxImages = 9}) async {
    state = ImageUploadState.selecting;
    
    _selectedImages = await _service.pickMultipleImages(maxImages: maxImages);
    
    if (_selectedImages.isNotEmpty) {
      state = ImageUploadState.idle;
    } else {
      state = ImageUploadState.idle;
    }
  }
  
  /// 拍照
  Future<void> takePhoto() async {
    state = ImageUploadState.selecting;
    
    final file = await _service.takePhoto();
    
    if (file != null) {
      _selectedImages = [file];
      state = ImageUploadState.idle;
    } else {
      state = ImageUploadState.idle;
    }
  }
  
  /// 上传图片
  Future<bool> uploadImages() async {
    if (_selectedImages.isEmpty) return false;
    
    state = ImageUploadState.uploading;
    _progress = 0;
    
    try {
      _uploadedImages = await _service.uploadMultipleImages(
        _selectedImages,
        onProgress: (progress) {
          _progress = progress;
          // 触发 UI 更新
          state = ImageUploadState.uploading;
        },
      );
      
      state = ImageUploadState.uploaded;
      return true;
    } catch (e) {
      state = ImageUploadState.error;
      return false;
    }
  }
  
  /// 清除选择
  void clearSelection() {
    _selectedImages = [];
    _uploadedImages = [];
    _progress = 0;
    state = ImageUploadState.idle;
  }
  
  /// 重置状态
  void reset() {
    clearSelection();
    state = ImageUploadState.idle;
  }
}

/// 图片上传按钮组件
class ImageUploadButton extends ConsumerWidget {
  final Function(List<String>)? onImagesUploaded;
  final int maxImages;
  final bool showPreview;
  
  const ImageUploadButton({
    super.key,
    this.onImagesUploaded,
    this.maxImages = 9,
    this.showPreview = true,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(imageUploadProvider.notifier);
    final state = ref.watch(imageUploadProvider);
    final selectedImages = notifier.selectedImages;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 相册按钮
        IconButton(
          icon: const Icon(Icons.photo_library),
          onPressed: () => notifier.pickImages(maxImages: maxImages),
          tooltip: '从相册选择',
        ),
        // 拍照按钮
        IconButton(
          icon: const Icon(Icons.camera_alt),
          onPressed: () => notifier.takePhoto(),
          tooltip: '拍照',
        ),
        // 上传按钮
        if (selectedImages.isNotEmpty)
          IconButton(
            icon: state == ImageUploadState.uploading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload),
            onPressed: state == ImageUploadState.uploading
                ? null
                : () async {
                    final success = await notifier.uploadImages();
                    if (success && onImagesUploaded != null) {
                      final uploadState = ref.read(imageUploadProvider);
                      final notifierState = notifier.uploadedImages;
                      final urls = notifierState.map((img) => img.url).toList();
                      onImagesUploaded!(urls);
                    }
                  },
            tooltip: '上传',
          ),
      ],
    );
  }
}

/// 图片预览网格组件
class ImagePreviewGrid extends ConsumerWidget {
  final List<String> imageUrls;
  final Function(int)? onRemove;
  final bool editable;
  
  const ImagePreviewGrid({
    super.key,
    required this.imageUrls,
    this.onRemove,
    this.editable = true,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image),
                  );
                },
              ),
            ),
            if (editable && onRemove != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => onRemove!(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
