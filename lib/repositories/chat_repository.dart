

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
  /// create chat room
  Future<void> createOrUpdateChatRoom(ChatRoomModel chatRoom) async {
    await _firestoreService.createOrUpdateChatRoom(chatRoom);
  }

  /// fetch existing chat room

  Stream<List<ChatRoomModel>> getUserChatRooms(String userId) {
    return _firestoreService.getUserChatRooms(userId);
  }
  /// send message
  Future<void> sendMessage(MessageModel message) async {
    await _firestoreService.sendMessage(message);
  }

  /// fetch conversation between two user

  Stream<List<MessageModel>> getChatMessages(String chatRoomId) {
    return _firestoreService.getChatMessages(chatRoomId);
  }

  /// check read and unread status

  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    await _firestoreService.markMessagesAsRead(chatRoomId, userId);
  }

  /// upload message image

  Future<String?> uploadMessageImage(File file) async {
    return await _storageService.uploadMessageImage(file);
  }

  /// generate chat Room

  Future<void> createChatRoom(ChatRoomModel chatRoom) async {
    await _firestoreService.createOrUpdateChatRoom(chatRoom);
  }
}