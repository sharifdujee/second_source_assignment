import 'dart:developer';
import 'dart:io';

import 'package:chat_application/core/constants/app_constants.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// here all of the firebase storage related task

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// update profile picture

  Future<String?> uploadProfilePicture(File file, String userId) async {
    try {
      final ref = _storage.ref().child(BackendConstants.profilePicturesPath).child('$userId.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      log('Error uploading profile picture: $e');
      return null;
    }
  }

  /// upload image when send message

  Future<String?> uploadMessageImage(File file) async {
    try {
      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child(BackendConstants.messageImagesPath).child(fileName);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      log('Error uploading message image: $e');
      return null;
    }
  }
}