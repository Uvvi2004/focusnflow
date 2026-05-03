import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
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

  // Upload profile avatar to Firebase Storage
  Future<String?> uploadAvatar(File file, String uid) async {
    try {
      final ref = _storage.ref().child('avatars/$uid/profile.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      // Save URL to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'photoURL': url}, SetOptions(merge: true));

      return url;
    } catch (e) {
      return null;
    }
  }

}