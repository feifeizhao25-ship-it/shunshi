import 'dart:io';
import 'package:dio/dio.dart';
import '../network/api_client.dart';

/// 文件上传服务
///
/// 支持:
/// - 图片上传 (头像、内容配图)
/// - 音频上传
/// - 通用文件上传
///
/// 后端 API:
/// - POST /api/v1/upload/image
/// - POST /api/v1/upload/audio
/// - POST /api/v1/upload/file
class UploadService {
  final Dio _dio;

  UploadService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  /// 上传图片
  ///
 /// [file] 图片文件
  /// [folder] 上传目录: avatar / content / chat
  Future<UploadResult> uploadImage(File file, {String folder = 'content'}) async {
    return await _upload(
      file: file,
      endpoint: '/upload/image',
      folder: folder,
      allowedTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
      maxSizeBytes: 10 * 1024 * 1024, // 10MB
    );
  }

  /// 上传音频
  Future<UploadResult> uploadAudio(File file, {String folder = 'audio'}) async {
    return await _upload(
      file: file,
      endpoint: '/upload/audio',
      folder: folder,
      allowedTypes: ['audio/mpeg', 'audio/mp4', 'audio/wav'],
      maxSizeBytes: 50 * 1024 * 1024, // 50MB
    );
  }

  /// 通用文件上传
  Future<UploadResult> uploadFile(
    File file, {
    required String endpoint,
    String folder = 'files',
    List<String>? allowedTypes,
    int? maxSizeBytes,
  }) async {
    return await _upload(
      file: file,
      endpoint: endpoint,
      folder: folder,
      allowedTypes: allowedTypes,
      maxSizeBytes: maxSizeBytes,
    );
  }

  /// 底层上传方法
  Future<UploadResult> _upload({
    required File file,
    required String endpoint,
    required String folder,
    List<String>? allowedTypes,
    int? maxSizeBytes,
  }) async {
    try {
      // 验证文件大小
      final fileSize = await file.length();
      if (maxSizeBytes != null && fileSize > maxSizeBytes) {
        return UploadResult.failure(
          message: '文件过大，最大允许 ${(maxSizeBytes / 1024 / 1024).toStringAsFixed(1)}MB',
        );
      }

      // 验证文件类型
      final mimeType = _getMimeType(file.path);
      if (allowedTypes != null && !allowedTypes.contains(mimeType)) {
        return UploadResult.failure(
          message: '不支持的文件类型: $mimeType',
        );
      }

      // 构建 multipart form
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
          contentType: DioMediaType.parse(mimeType),
        ),
        'folder': folder,
      });

      // 发送请求
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
        onSendProgress: (sent, total) {
          final progress = total > 0 ? sent / total : 0;
          print('[Upload] 进度: ${(progress * 100).toStringAsFixed(1)}%');
        },
      );

      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        return UploadResult.success(
          url: data['data']['url'],
          fileId: data['data']['id'],
          message: '上传成功',
        );
      }

      return UploadResult.failure(message: data['error'] ?? '上传失败');
    } on DioException catch (e) {
      return UploadResult.failure(
        message: '上传失败: ${e.message}',
        code: e.response?.statusCode?.toString(),
      );
    } catch (e) {
      return UploadResult.failure(message: '未知错误: $e');
    }
  }

  /// 获取 MIME 类型
  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    final map = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
      'gif': 'image/gif',
      'mp3': 'audio/mpeg',
      'm4a': 'audio/mp4',
      'wav': 'audio/wav',
      'mp4': 'video/mp4',
      'pdf': 'application/pdf',
    };
    return map[ext] ?? 'application/octet-stream';
  }
}

/// 上传结果
class UploadResult {
  final bool success;
  final String? url;
  final String? fileId;
  final String? message;
  final String? code;

  UploadResult._({
    required this.success,
    this.url,
    this.fileId,
    this.message,
    this.code,
  });

  factory UploadResult.success({
    required String url,
    required String fileId,
    required String message,
  }) => UploadResult._(
    success: true,
    url: url,
    fileId: fileId,
    message: message,
  );

  factory UploadResult.failure({
    required String message,
    String? code,
  }) => UploadResult._(
    success: false,
    message: message,
    code: code,
  );
}

// Dio 4.x 兼容性处理
typedef DioMediaType = MediaType;

/// 全局实例
final uploadService = UploadService();
