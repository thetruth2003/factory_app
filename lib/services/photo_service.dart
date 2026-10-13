import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class PhotoService {
  PhotoService(this._db, this._storage);
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  final ImagePicker _picker = ImagePicker();
  final Map<String, String> _photoIds = {};
  final Set<String> _completed = {};

  Future<List<XFile>> pickMultiple({int imageQuality = 85}) async {
    final files = await _picker.pickMultiImage(imageQuality: imageQuality);
    return files;
  }

  Future<XFile?> pickSingle({int imageQuality = 85}) async {
    return _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: imageQuality,
    );
  }

  /// Upload -> Storage
  /// Write -> incidents/{id}/photos/{photoId}
  /// Event -> incidents/{id}/events/{eventId} (photo_added)
  Future<void> uploadIncidentPhotos({
    required String incidentId,
    required String byUid,
    required String byName,
    required String byRole,
    required List<XFile> files,
  }) async {
    if (files.isEmpty) return;

    final incRef = _db.collection('incidents').doc(incidentId);
    final photosCol = incRef.collection('photos');
    final eventsCol = incRef.collection('events');

    for (final f in files) {
      final uploadKey = '$incidentId/${f.path}';
      if (_completed.contains(uploadKey)) continue;
      final photoId = _photoIds.putIfAbsent(
        uploadKey,
        () => photosCol.doc().id,
      );
      final extension = f.name.toLowerCase().endsWith('.png')
          ? 'png'
          : f.name.toLowerCase().endsWith('.heic')
          ? 'heic'
          : 'jpg';
      final storagePath = 'incidents/$incidentId/$photoId.$extension';
      final ref = _storage.ref(storagePath);

      final bytes = await f.readAsBytes();
      final task = await ref.putData(
        bytes,
        SettableMetadata(
          contentType:
              f.mimeType ??
              (extension == 'png'
                  ? 'image/png'
                  : extension == 'heic'
                  ? 'image/heic'
                  : 'image/jpeg'),
        ),
      );

      final url = await task.ref.getDownloadURL();

      final batch = _db.batch();

      batch.set(photosCol.doc(photoId), {
        'url': url,
        'path': storagePath,
        'createdAt': FieldValue.serverTimestamp(),
        'byUid': byUid,
        'byName': byName.trim(),
        'byRole': byRole,
      });

      batch.set(eventsCol.doc('photo_$photoId'), {
        'type': 'photo_added',
        'at': FieldValue.serverTimestamp(),
        'byUid': byUid,
        'byName': byName.trim(),
        'byRole': byRole,
        'message': 'photo uploaded',
        'meta': {'photoId': photoId, 'path': storagePath},
      });

      batch.update(incRef, {'updatedAt': FieldValue.serverTimestamp()});

      await batch.commit();
      _completed.add(uploadKey);
    }
  }
}
