

import 'package:chat_application/core/constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../models/user.dart';

/// here all of the function related firebase cloud fireStore

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// create new user
  Future<void> createUser(UserModel user) async {
    await _firestore
        .collection(BackendConstants.usersCollection)
        .doc(user.uid)
        .set(user.toMap());
  }

  /// get user data based on the user id

  Future<UserModel?> getUser(String uid) async {
    log("📡 Fetching user with uid: $uid");

    final doc = await _firestore
        .collection(BackendConstants.usersCollection)
        .doc(uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      log("✅ User document found: $data");
      final user = UserModel.fromMap(data!);
      log("👤 Parsed UserModel => uid: ${user.uid}, name: ${user.displayName}, email: ${user.email}");
      return user;
    } else {
      log("⚠️ No user found with uid: $uid");
    }

    return null;
  }
  /// update user information
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection(BackendConstants.usersCollection)
        .doc(uid)
        .update(data);
  }
 /// fetch others user for messaging
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection(BackendConstants.usersCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList());
  }

  /// create Chat Room
  Future<void> createOrUpdateChatRoom(ChatRoomModel chatRoom) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    log("🏠 Creating/updating chat room: ${chatRoom.chatRoomId}");
    log("👥 Participants: ${chatRoom.participants}");
    log("🔐 Current user: ${currentUser.uid}");
    await _firestore
        .collection(BackendConstants.chatRoomsCollection)
        .doc(chatRoom.chatRoomId)
        .set(chatRoom.toMap(), SetOptions(merge: true));

    log("✅ Chat room created/updated successfully");
  }
    /// fetch previous chat room
  Stream<List<ChatRoomModel>> getUserChatRooms(String userId) {
    return _firestore
        .collection(BackendConstants.chatRoomsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatRoomModel.fromMap(doc.data()))
        .toList());
  }

  /// check chat room exist or not before start the messaging
  Future<void> ensureChatRoomExists(String chatRoomId, String senderId, String receiverId) async {
    try {
      final doc = await _firestore
          .collection(BackendConstants.chatRoomsCollection)
          .doc(chatRoomId)
          .get();

      if (!doc.exists) {
        log("🆕 Creating new chat room: $chatRoomId");
        final chatRoom = ChatRoomModel(
          chatRoomId: chatRoomId,
          participants: [senderId, receiverId],
          lastMessage: '',
          lastMessageTime: DateTime.now(),
          lastMessageSenderId: '',
          unreadCount: {senderId: 0, receiverId: 0},
        );

        await createOrUpdateChatRoom(chatRoom);
        log("✅ Chat room created successfully");
      } else {
        log("✅ Chat room already exists");
      }
    } catch (e) {
      log("❌ Error ensuring chat room exists: $e");

    }
  }

/// this is the send message functionality , check user is authenticated or not

  Future<void> sendMessage(MessageModel message) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    log("📤 Sending message: ${message.content}");
    log("👤 From: ${message.senderId} To: ${message.receiverId}");
    log("🏠 Chat room: ${message.chatRoomId}");

    try {
      /// STEP 1: Ensure chat room exists
      await ensureChatRoomExists(message.chatRoomId, message.senderId, message.receiverId);

      /// STEP 2: Create message document with proper error handling
      final messageRef = _firestore
          .collection(BackendConstants.chatRoomsCollection)
          .doc(message.chatRoomId)
          .collection(BackendConstants.messagesCollection)
          .doc(message.messageId);

      /// Use a transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        // Add message
        transaction.set(messageRef, message.toMap());

        /// Update chat room
        final chatRoomRef = _firestore
            .collection(BackendConstants.chatRoomsCollection)
            .doc(message.chatRoomId);

        transaction.update(chatRoomRef, {
          'lastMessage': message.content,
          'lastMessageTime': message.timestamp,
          'lastMessageSenderId': message.senderId,
          'unreadCount.${message.receiverId}': FieldValue.increment(1),
        });
      });

      log("✅ Message and chat room updated successfully");
    } catch (e) {
      log(" Error sending message: $e");
      rethrow;
    }
  }
 /// get all of the message between two user
  Stream<List<MessageModel>> getChatMessages(String chatRoomId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    log("📡 Setting up message listener for: $chatRoomId");

    return _firestore
        .collection(BackendConstants.chatRoomsCollection)
        .doc(chatRoomId)
        .collection(BackendConstants.messagesCollection)
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: false) // Important: exclude metadata changes
        .handleError((error) {
      log("Error listening to messages: $error");
      if (error.toString().contains('permission-denied')) {
        log(" Permission denied, returning empty stream");
        return <MessageModel>[];
      }
      throw error;
    })
        .map((snapshot) {
      log("📥 Raw snapshot: ${snapshot.docs.length} documents");

      final messages = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          log("📄 Message data: $data");
          return MessageModel.fromMap(data);
        } catch (e) {
          log("Error parsing message ${doc.id}: $e");
          return null;
        }
      })
          .where((message) => message != null)
          .cast<MessageModel>()
          .toList();

      log("📥 Parsed ${messages.length} messages successfully");
      return messages;
    });
  }

  /// check message status it's read or not

  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      log(" User not authenticated for markMessagesAsRead");
      return;
    }

    try {
      log("Marking messages as read for user: $userId in chat: $chatRoomId");

      /// Check if chat room exists first
      final doc = await _firestore
          .collection(BackendConstants.chatRoomsCollection)
          .doc(chatRoomId)
          .get();

      if (!doc.exists) {
        log("Chat room doesn't exist, cannot mark as read");
        return;
      }

      await _firestore
          .collection(BackendConstants.chatRoomsCollection)
          .doc(chatRoomId)
          .update({'unreadCount.$userId': 0});

      log("✅ Messages marked as read successfully");

    } catch (e) {
      log(" Error marking messages as read (non-critical): $e");

    }
  }

  ///Helper method to generate chat room ID
  static String generateChatRoomId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
}
