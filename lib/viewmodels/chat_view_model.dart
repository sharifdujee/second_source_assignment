import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_room.dart';
import '../models/message.dart';
import '../repositories/chat_repository.dart';


/// this is the chat view model to handle the chat relate business logic here


class ChatState {
  final bool isLoading;
  final List<MessageModel> messages;
  final bool isSending;
  final String? error;

  ChatState({
    this.isLoading = false,
    this.messages = const [],
    this.isSending = false,
    this.error,
  });
  /// copy with function use basically for immutable state objects
  ChatState copyWith({
    bool? isLoading,
    List<MessageModel>? messages,
    bool? isSending,
    String? error,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

class ChatViewModel extends StateNotifier<ChatState> {
  final ChatRepository _chatRepository;
  final String chatRoomId;
  final String currentUserId;
  final String otherUserId;
  final Uuid _uuid = const Uuid();

  StreamSubscription? _messageSubscription;
  bool _isInitialized = false;

  ChatViewModel({
    required ChatRepository chatRepository,
    required this.chatRoomId,
    required this.currentUserId,
    required this.otherUserId,
  }) : _chatRepository = chatRepository,
        super(ChatState()) {

    _initializeChat();
  }

  @override
  void dispose() {

    _messageSubscription?.cancel();
    super.dispose();
  }

  /// Here initialized the chat

  Future<void> _initializeChat() async {
    if (_isInitialized) {

      return;
    }

    try {
      _isInitialized = true;
      state = state.copyWith(isLoading: true, error: null);


      /// STEP 1: first create the chat room
      await _ensureChatRoomExists();

      ///  Set up message listener with a small delay
      await Future.delayed(const Duration(milliseconds: 300));
      _loadMessages();
      /// after message load check it's already read or not
      _markMessagesAsRead();
    } catch (e) {

      if (mounted) {
        state = state.copyWith(error: e.toString(), isLoading: false);
      }
    }
  }
  /// here check the chat room is exist or not
  Future<void> _ensureChatRoomExists() async {
    try {
      final chatRoom = ChatRoomModel(
        chatRoomId: chatRoomId,
        participants: [currentUserId, otherUserId],
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        lastMessageSenderId: '',
        unreadCount: {currentUserId: 0, otherUserId: 0},
      );
      await _chatRepository.createOrUpdateChatRoom(chatRoom);

    } catch (e) {
      log("The exception is ${e.toString()}");


    }
  }
  /// load previous message of the room
  void _loadMessages() {
    try {

      _messageSubscription?.cancel();

      _messageSubscription = _chatRepository.getChatMessages(chatRoomId).listen(
            (messages) {



          if (mounted) {

            final newState = state.copyWith(
              messages: messages,
              isLoading: false,
              error: null,
            );

            state = newState;

          } else {
            log("ViewModel not mounted, skipping state update");
          }
        },
        onError: (error) {
          log("Error in message listener: $error");
          if (mounted) {
            state = state.copyWith(
              isLoading: false,
              error: error.toString(),
            );
          }
        },
      );
    } catch (e) {
      log(" Error setting up message listener: $e");
      if (mounted) {
        state = state.copyWith(error: e.toString(), isLoading: false);
      }
    }
  }
   /// send text message functionality
  Future<void> sendTextMessage(String content) async {
    if (content.trim().isEmpty) return;

    log("🚀 Sending message: '$content' from chatRoom: $chatRoomId");

    /// Create the actual message to send, after send the message display the message in UI.
    final message = MessageModel(
      messageId: _uuid.v4(),
      senderId: currentUserId,
      receiverId: otherUserId,
      chatRoomId: chatRoomId,
      content: content,
      type: MessageType.text,
      timestamp: DateTime.now(),
      isRead: false,
    );

    /// Show optimistic update immediately
    final currentMessages = List<MessageModel>.from(state.messages);
    currentMessages.insert(0, message); // Add to top (newest first)

    if (mounted) {
      state = state.copyWith(
        messages: currentMessages,
        isSending: true,
        error: null,
      );

    }

    try {
      await _chatRepository.sendMessage(message);
      /// send message on firebase
    } catch (e) {
      log(" Error sending message: $e");

      // Remove optimistic message on failure
      if (mounted) {
        final messagesWithoutOptimistic = state.messages
            .where((msg) => msg.messageId != message.messageId)
            .toList();

        state = state.copyWith(
          messages: messagesWithoutOptimistic,
          error: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        state = state.copyWith(isSending: false);
      }
    }
  }
  /// send image in message
  Future<void> sendImageMessage(File imageFile) async {
    if (mounted) {
      state = state.copyWith(isSending: true, error: null);
    }

    try {
      final imageUrl = await _chatRepository.uploadMessageImage(imageFile);
      /// after send the message if image is not null display the image in UI before display first it send in server
      if (imageUrl != null) {
        final message = MessageModel(
          messageId: _uuid.v4(),
          senderId: currentUserId,
          receiverId: otherUserId,
          chatRoomId: chatRoomId,
          content: 'Image',
          type: MessageType.image,
          timestamp: DateTime.now(),
          isRead: false,
          imageUrl: imageUrl,
        );

        await _chatRepository.sendMessage(message);
      }
    } catch (e) {
      log(" Error sending image: $e");
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    } finally {
      if (mounted) {
        state = state.copyWith(isSending: false);
      }
    }
  }
  /// check message status it's read or not
  Future<void> _markMessagesAsRead() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      await _chatRepository.markMessagesAsRead(chatRoomId, currentUserId);
    } catch (e) {
      log("⚠️ Could not mark messages as read: $e");
    }
  }

  void retry() {
    _isInitialized = false;
    _initializeChat();
  }

  void clearError() {
    if (mounted) {
      state = state.copyWith(error: null);
    }
  }

  static String generateChatRoomId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
}
