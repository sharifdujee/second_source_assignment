import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_room.dart';
import '../models/message.dart';
import '../repositories/chat_repository.dart';



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
    print("🎯 ChatViewModel constructor called for chatRoom: $chatRoomId");
    _initializeChat();
  }

  @override
  void dispose() {
    print("🗑️ Disposing ChatViewModel for chatRoom: $chatRoomId");
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    if (_isInitialized) {
      print("⚠️ Chat already initialized, skipping");
      return;
    }

    try {
      _isInitialized = true;
      state = state.copyWith(isLoading: true, error: null);
      print("🚀 Initializing chat: $chatRoomId");
      print("👤 Current user: $currentUserId");
      print("👤 Other user: $otherUserId");

      // STEP 1: Create initial chat room
      await _ensureChatRoomExists();

      // STEP 2: Set up message listener with a small delay
      await Future.delayed(const Duration(milliseconds: 300));
      _loadMessages();

      // STEP 3: Mark messages as read (non-critical)
      _markMessagesAsRead();
    } catch (e) {
      print("❌ Error initializing chat: $e");
      if (mounted) {
        state = state.copyWith(error: e.toString(), isLoading: false);
      }
    }
  }

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
      print("✅ Chat room ensured to exist");
    } catch (e) {
      print("❌ Error ensuring chat room exists: $e");
      throw e;
    }
  }

  void _loadMessages() {
    try {
      print("📡 Setting up message listener for chatRoom: $chatRoomId");

      // Cancel existing subscription if any
      _messageSubscription?.cancel();

      _messageSubscription = _chatRepository.getChatMessages(chatRoomId).listen(
            (messages) {
          print("📥 Received ${messages.length} messages in chatRoom: $chatRoomId");

          // Ensure we're still mounted before updating state
          if (mounted) {
            // Force state update with debug info
            final newState = state.copyWith(
              messages: messages,
              isLoading: false,
              error: null,
            );

            state = newState;
            print("✅ State updated with ${newState.messages.length} messages");
            print("🔍 Current state has ${state.messages.length} messages");
          } else {
            print("⚠️ ViewModel not mounted, skipping state update");
          }
        },
        onError: (error) {
          print("❌ Error in message listener: $error");
          if (mounted) {
            state = state.copyWith(
              isLoading: false,
              error: error.toString(),
            );
          }
        },
      );
    } catch (e) {
      print("❌ Error setting up message listener: $e");
      if (mounted) {
        state = state.copyWith(error: e.toString(), isLoading: false);
      }
    }
  }

  Future<void> sendTextMessage(String content) async {
    if (content.trim().isEmpty) return;

    print("🚀 Sending message: '$content' from chatRoom: $chatRoomId");

    // Create the actual message to send
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

    // Show optimistic update immediately
    final currentMessages = List<MessageModel>.from(state.messages);
    currentMessages.insert(0, message); // Add to top (newest first)

    if (mounted) {
      state = state.copyWith(
        messages: currentMessages,
        isSending: true,
        error: null,
      );
      print("🎯 Optimistic update: added message to UI");
    }

    try {
      await _chatRepository.sendMessage(message);
      print("✅ Message sent successfully to Firebase");
      // The real message will come through the stream listener
    } catch (e) {
      print("❌ Error sending message: $e");

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

  Future<void> sendImageMessage(File imageFile) async {
    if (mounted) {
      state = state.copyWith(isSending: true, error: null);
    }

    try {
      final imageUrl = await _chatRepository.uploadMessageImage(imageFile);
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
      print("❌ Error sending image: $e");
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    } finally {
      if (mounted) {
        state = state.copyWith(isSending: false);
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      await _chatRepository.markMessagesAsRead(chatRoomId, currentUserId);
    } catch (e) {
      print("⚠️ Could not mark messages as read: $e");
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
