
import 'dart:io';

import '../models/user.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class UserRepository {
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  UserRepository({
    required FirestoreService firestoreService,
    required StorageService storageService,
  }) : _firestoreService = firestoreService,
        _storageService = storageService;
  /// create user
  Future<void> createUser(UserModel user) async {
    await _firestoreService.createUser(user);
  }

  /// fetch user information

  Future<UserModel?> getUser(String uid) async {
    return await _firestoreService.getUser(uid);
  }

  /// update user information

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestoreService.updateUser(uid, data);
  }

  /// fetch others user information

  Stream<List<UserModel>> getAllUsers() {
    return _firestoreService.getAllUsers();
  }
  /// update profile picture
  Future<String?> uploadProfilePicture(File file, String userId) async {
    return await _storageService.uploadProfilePicture(file, userId);
  }

  /// update user online and offline status and last time user available

  Future<void> updateUserStatus(String userId, bool isOnline) async {
    await _firestoreService.updateUser(userId, {
      'isOnline': isOnline,
      'lastSeen': DateTime.now(),
    });
  }
}
