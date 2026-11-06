import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Largest full-size photo we will save. A Firestore document can hold at
/// most 1 MiB, and base64 text is about 33% bigger than the raw bytes,
/// so 700 KB of JPEG becomes about 950 KB of text - just under the limit.
const int maxImageBytes = 700 * 1024;

/// Width (in pixels) of the full-size photo.
const int fullImageWidth = 1024;

/// Width (in pixels) of the small preview shown on list cards.
const int thumbnailWidth = 200;

/// Thrown when a picked file can't be turned into a small enough photo.
class ImageProcessingException implements Exception {
  const ImageProcessingException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A photo ready to save: the full-size JPEG and a tiny thumbnail JPEG.
class CompressedImage {
  const CompressedImage({
    required this.fullBytes,
    required this.thumbnailBytes,
  });

  final Uint8List fullBytes;
  final Uint8List thumbnailBytes;

  String get thumbnailBase64 => base64Encode(thumbnailBytes);
}

/// Shrinks a photo so it fits in Firestore, and makes a thumbnail.
///
/// This is a plain function (no Firebase, no widgets) so it can be unit
/// tested and run on a background isolate with compute().
CompressedImage compressImage(Uint8List originalBytes) {
  final decoded = img.decodeImage(originalBytes);
  if (decoded == null) {
    throw const ImageProcessingException('That file is not a supported image.');
  }

  // image_picker already resizes to 1024px wide on phones, but on some
  // platforms it can't, so we make sure here.
  var fullImage = decoded;
  var fullBytes = originalBytes;
  if (decoded.width > fullImageWidth) {
    fullImage = img.copyResize(decoded, width: fullImageWidth);
    fullBytes = img.encodeJpg(fullImage, quality: 60);
  }

  // Still too big? Try lower quality settings before giving up.
  for (final quality in [50, 40, 30]) {
    if (fullBytes.length <= maxImageBytes) break;
    fullBytes = img.encodeJpg(fullImage, quality: quality);
  }
  if (fullBytes.length > maxImageBytes) {
    throw const ImageProcessingException(
      'This photo is too large. Please choose a different one.',
    );
  }

  // Don't stretch photos that are already narrower than a thumbnail.
  final thumbnail = decoded.width > thumbnailWidth
      ? img.copyResize(decoded, width: thumbnailWidth)
      : decoded;
  final thumbnailBytes = img.encodeJpg(thumbnail, quality: 50);

  return CompressedImage(fullBytes: fullBytes, thumbnailBytes: thumbnailBytes);
}

/// Picks, saves and loads incident photos.
///
/// This is an abstract class: it describes what an image service can do,
/// and the two classes below provide the "how". The rest of the app only
/// knows about ImageService, so we can switch storage with one flag
/// (useFirebaseStorage in core/constants.dart).
abstract class ImageService {
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Lets the user take or choose a photo, then compresses it.
  /// Returns null if the user cancels.
  Future<CompressedImage?> pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: fullImageWidth.toDouble(),
      imageQuality: 60,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    // Resizing is heavy work. compute() runs it on a background isolate
    // (a separate thread) so the UI doesn't freeze while it runs.
    return compute(compressImage, bytes);
  }

  /// Saves the full-size photo for an incident. Returns where it was saved.
  Future<String> uploadImage({
    required String incidentId,
    required String ownerId,
    required Uint8List bytes,
  });

  /// Loads the full-size photo for an incident, or null if there isn't one.
  Future<Uint8List?> loadImage(String incidentId);
}

/// ACTIVE: stores the photo as base64 text in incident_images/{incidentId}.
/// Works on the free Spark plan.
class FirestoreImageService extends ImageService {
  FirestoreImageService({required this._firestore, super.picker});

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _imageDoc(String incidentId) =>
      _firestore.collection('incident_images').doc(incidentId);

  @override
  Future<String> uploadImage({
    required String incidentId,
    required String ownerId,
    required Uint8List bytes,
  }) async {
    await _imageDoc(incidentId).set({
      'data': base64Encode(bytes),
      'ownerId': ownerId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return _imageDoc(incidentId).path;
  }

  @override
  Future<Uint8List?> loadImage(String incidentId) async {
    final snapshot = await _imageDoc(incidentId).get();
    final data = snapshot.data()?['data'] as String?;
    if (data == null) return null;
    return base64Decode(data);
  }
}

/// INACTIVE: uploads to Firebase Storage at incidents/{incidentId}.jpg.
/// Firebase Storage needs the paid Blaze plan (since Feb 2026), so this is
/// switched off, but it works if useFirebaseStorage is set to true.
class FirebaseStorageImageService extends ImageService {
  FirebaseStorageImageService({required this._storage, super.picker});

  final FirebaseStorage _storage;

  Reference _imageRef(String incidentId) =>
      _storage.ref('incidents/$incidentId.jpg');

  /// Returns the photo's public download URL.
  @override
  Future<String> uploadImage({
    required String incidentId,
    required String ownerId,
    required Uint8List bytes,
  }) async {
    final ref = _imageRef(incidentId);
    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'ownerId': ownerId},
      ),
    );
    return ref.getDownloadURL();
  }

  @override
  Future<Uint8List?> loadImage(String incidentId) async {
    try {
      return await _imageRef(incidentId).getData(maxImageBytes);
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return null;
      rethrow;
    }
  }
}
