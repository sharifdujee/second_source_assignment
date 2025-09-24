
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

  Future<void> createUser(UserModel user) async {
    await _firestoreService.createUser(user);
  }

  Future<UserModel?> getUser(String uid) async {
    return await _firestoreService.getUser(uid);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestoreService.updateUser(uid, data);
  }

  Stream<List<UserModel>> getAllUsers() {
    return _firestoreService.getAllUsers();
  }

  Future<String?> uploadProfilePicture(File file, String userId) async {
    return await _storageService.uploadProfilePicture(file, userId);
  }

  Future<void> updateUserStatus(String userId, bool isOnline) async {
    await _firestoreService.updateUser(userId, {
      'isOnline': isOnline,
      'lastSeen': DateTime.now(),
    });
  }
}
