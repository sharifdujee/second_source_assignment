

import 'dart:io';

import '../models/chat_room.dart';
import '../models/message.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ChatRepository {
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  ChatRepository({
    required FirestoreService firestoreService,
    required StorageService storageService,
  }) : _firestoreService = firestoreService,
        _storageService = storageService;

  Future<void> createOrUpdateChatRoom(ChatRoomModel chatRoom) async {
    await _firestoreService.createOrUpdateChatRoom(chatRoom);
  }

  Stream<List<ChatRoomModel>> getUserChatRooms(String userId) {
    return _firestoreService.getUserChatRooms(userId);
  }

  Future<void> sendMessage(MessageModel message) async {
    await _firestoreService.sendMessage(message);
  }

  Stream<List<MessageModel>> getChatMessages(String chatRoomId) {
    return _firestoreService.getChatMessages(chatRoomId);
  }

  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    await _firestoreService.markMessagesAsRead(chatRoomId, userId);
  }

  Future<String?> uploadMessageImage(File file) async {
    return await _storageService.uploadMessageImage(file);
  }

  Future<void> createChatRoom(ChatRoomModel chatRoom) async {
    await _firestoreService.createOrUpdateChatRoom(chatRoom);
  }
}