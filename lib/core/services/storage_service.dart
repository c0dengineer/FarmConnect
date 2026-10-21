import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  /// Picks images; they are down-scaled/compressed by image_picker itself.
  static Future<List<XFile>> pick({int max = 4}) async {
    final files = await ImagePicker().pickMultiImage(imageQuality: 70, maxWidth: 1000);
    return files.take(max).toList();
  }

  static Future<List<String>> upload(List<XFile> files, String folder) async {
    final urls = <String>[];
    for (final f in files) {
      final ref = FirebaseStorage.instance.ref('$folder/${const Uuid().v4()}.jpg');
      await ref.putData(await f.readAsBytes(), SettableMetadata(contentType: 'image/jpeg'));
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }
}
