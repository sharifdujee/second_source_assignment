import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_application/widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_color.dart';
import '../../core/dependency_injection/app_provider.dart';
import '../../core/utils/app_utils.dart';
import '../../models/user.dart';
import '../../viewmodels/chat_view_model.dart';
import '../../widgets/message_bubble.dart';

final chatViewModelProvider = StateNotifierProvider.autoDispose
    .family<ChatViewModel, ChatState, Map<String, String>>((ref, params) {
      log("🔧 Creating ChatViewModel with params: $params");

      /// Keep reference to prevent disposal during navigation
      ref.keepAlive();

      /// create provider for chat repository

      final chatRepository = ref.watch(chatRepositoryProvider);
      return ChatViewModel(
        chatRepository: chatRepository,
        chatRoomId: params['chatRoomId']!,
        currentUserId: params['currentUserId']!,
        otherUserId: params['otherUserId']!,
      );
    });

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String chatRoomId;
  final UserModel otherUser;

  const ChatRoomScreen({
    super.key,
    required this.chatRoomId,
    required this.otherUser,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  /// Keep the screen alive to maintain provider state
  @override
  bool get wantKeepAlive => true;

  late final Map<String, String> _providerParams;

  @override
  /// initially check the user is already login or not and they can confirm the criteria to start the conversation
  void initState() {
    super.initState();

    final authState = ref.read(authViewModelProvider);
    _providerParams = {
      'chatRoomId': widget.chatRoomId,
      'currentUserId': authState.user!.uid,
      'otherUserId': widget.otherUser.uid,
    };
    log("ChatRoomScreen initState with params: $_providerParams");
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    /// Use consistent provider params
    final chatState = ref.watch(chatViewModelProvider(_providerParams));

    if (chatState.error != null) {}

    /// Listen for errors, if found error the user can try again , display a snack message
    ref.listen(chatViewModelProvider(_providerParams), (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                ref
                    .read(chatViewModelProvider(_providerParams).notifier)
                    .retry();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            /// in app bar display the other user profile picture, and name also their status they are online or offline, also display how long ago they are on online
            CircleAvatar(
              radius: 18,
              backgroundImage:
                  widget.otherUser.profilePictureUrl != null
                      ? CachedNetworkImageProvider(
                        widget.otherUser.profilePictureUrl!,
                      )
                      : null,
              child:
                  widget.otherUser.profilePictureUrl == null
                      ? Text(widget.otherUser.displayName[0].toUpperCase())
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.displayName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    widget.otherUser.isOnline
                        ? 'Online'
                        : 'Last seen ${AppUtils.formatTimestamp(widget.otherUser.lastSeen)}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            /// the message list widget only used here for that not create custom widget outside the class, for single use it's create here
            child: _buildMessagesList(chatState),
          ),
          _buildMessageInput(context, chatState),
        ],
      ),
    );
  }

  /// Here display the previous conversation list between user and selected user
  Widget _buildMessagesList(ChatState chatState) {
    if (chatState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading messages...'),
          ],
        ),
      );
    }

    /// if message is empty display the message
    if (chatState.messages.isEmpty) {
      return Center(
        child: CustomText(
          text: "No messages yet.\nSend a message to start the conversation!",
          textAlign: TextAlign.center,
          fontSize: 16,
          color: AppColors.grey,
        ),
      );
    }
  /// list view used for display all message and scroll it.
    return ListView.builder(
      controller: _scrollController,
      /// use revers true display last message at bottom
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chatState.messages.length,
      itemBuilder: (context, index) {
        final message = chatState.messages[index];
        final authState = ref.read(authViewModelProvider);
        final isCurrentUser = message.senderId == authState.user!.uid;



        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          /// message bubble can found in widget directory
          child: MessageBubble(
            message: message,
            isCurrentUser: isCurrentUser,
            otherUserImage:
                isCurrentUser ? null : widget.otherUser.profilePictureUrl,
          ),
        );
      },
    );
  }
  /// The input field here user can enter their text message inside the text field, when click the send button message is send
  Widget _buildMessageInput(BuildContext context, ChatState chatState) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: chatState.isSending ? null : _pickImage,
            icon: const Icon(Icons.photo_camera),
            color: Colors.grey[600],
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          chatState.isSending
              ? const SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
              : IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send),
                color: Theme.of(context).primaryColor,
              ),
        ],
      ),
    );
  }

  /// Here is the send message functionality

  void _sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;



    ref
        .read(chatViewModelProvider(_providerParams).notifier)
        .sendTextMessage(messageText);

    _messageController.clear();

    // Auto-scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  /// user can send image message from their phone gallery
  void _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        ref
            .read(chatViewModelProvider(_providerParams).notifier)
            .sendImageMessage(File(pickedFile.path));
      }
    } catch (e) {
     log("The exception is ${e.toString()}");
    }
  }
}
