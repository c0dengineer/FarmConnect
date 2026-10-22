import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  // Cloudinary unsigned upload configuration. These values are identifiers,
  // not secrets. Set them with --dart-define at build/run time.
  static const _cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const _uploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');
  static bool get isConfigured => _cloudName.isNotEmpty && _uploadPreset.isNotEmpty;

  /// Picks images; they are down-scaled/compressed by image_picker itself.
  static Future<List<XFile>> pick({int max = 4}) async {
    final files = await ImagePicker().pickMultiImage(imageQuality: 70, maxWidth: 1000);
    return files.take(max).toList();
  }

  static Future<List<String>> upload(List<XFile> files, String folder) async {
    if (files.isEmpty) return const [];
    if (!isConfigured) {
      throw StateError(
        'Photo uploads are not configured. Set CLOUDINARY_CLOUD_NAME and '
        'CLOUDINARY_UPLOAD_PRESET using --dart-define.',
      );
    }

    final urls = <String>[];
    for (final f in files) {
      final bytes = await f.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        throw StateError('Each photo must be 5 MB or smaller.');
      }
      final extension = _imageExtension(f.name);
      final subtype = extension == 'jpg' ? 'jpeg' : extension;
      final section = folder.startsWith('farms/')
          ? 'farms'
          : folder.startsWith('products/')
              ? 'products'
              : 'misc';
      final publicId = 'farmconnect/$section/${const Uuid().v4()}.$extension';
      final request = http.MultipartRequest(
        'POST',
        Uri.https('api.cloudinary.com', '/v1_1/$_cloudName/image/upload'),
      )
        ..fields['upload_preset'] = _uploadPreset
        // Use only a known section name in the remote path, never the caller's
        // user ID or an arbitrary path.
        ..fields['public_id'] = publicId
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: publicId.split('/').last,
            contentType: MediaType('image', subtype),
          ),
        );

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300 || data is! Map) {
        final message = data is Map && data['error'] is Map
            ? data['error']['message']
            : null;
        throw StateError('Image upload failed${message == null ? '' : ': $message'}');
      }

      final url = data['secure_url'];
      if (url is! String || !url.startsWith('https://')) {
        throw StateError('Image service returned an invalid image URL.');
      }
      urls.add(url);
    }
    return urls;
  }

  /// Old Firebase Storage links are unusable on the free Firebase plan.
  /// Remove them when replacing images with newly uploaded Cloudinary URLs.
  static List<String> mergeImageUrls(
    List<String> existing,
    List<String> uploaded,
  ) {
    final kept = uploaded.isEmpty
        ? existing
        : existing.where((url) =>
            !url.contains('firebasestorage.googleapis.com') &&
            !url.contains('.firebasestorage.app/'));
    return [...kept, ...uploaded];
  }

  static String _imageExtension(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    // The picker accepts common image formats; reject anything else before
    // sending it to the image host.
    if (!const {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'}
        .contains(extension)) {
      throw StateError('Unsupported image format. Choose a JPG, PNG, or WebP image.');
    }
    return extension == 'jpeg' ? 'jpg' : extension;
  }
}
