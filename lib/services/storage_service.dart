import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Handles all Firebase Storage operations — picking images from the gallery
// and uploading them to Storage with the download URL saved back to Firestore.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Opens the device gallery and returns the selected image.
  // We compress and resize here (512x512, 75% quality) to keep
  // Storage usage low and uploads fast.
  Future<File?> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  // Uploads the user's profile photo to Storage at avatars/{uid}/profile.jpg.
  // After a successful upload, the download URL is saved to the user's
  // Firestore document so every screen that displays their avatar stays in sync.
  Future<String?> uploadAvatar(File file, String uid) async {
    try {
      // Path follows the convention in storage.rules: avatars/{userId}/{file}
      final ref = _storage.ref().child('avatars/$uid/profile.jpg');
      await ref.putFile(file);

      // Get the public download URL from Storage CDN.
      final url = await ref.getDownloadURL();

      // Merge the URL into the existing user doc — doesn't overwrite other fields.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'photoURL': url}, SetOptions(merge: true));

      return url;
    } catch (e) {
      return null; // silently return null so the UI can handle it gracefully
    }
  }
}
