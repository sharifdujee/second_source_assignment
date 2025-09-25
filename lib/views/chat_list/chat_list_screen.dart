import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_application/core/constants/app_color.dart';
import 'package:chat_application/widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dependency_injection/app_provider.dart';
import '../../core/utils/app_utils.dart';





class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  /// initially loading the chatRoom also others user data
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authViewModelProvider);
      if (authState.user != null) {
        ref.read(chatListViewModelProvider.notifier).loadUserChatRooms(authState.user!.uid);
        ref.read(chatListViewModelProvider.notifier).loadAllUsers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    /// create provider for auth state and chat list state 
    final authState = ref.watch(authViewModelProvider);
    final chatListState = ref.watch(chatListViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        
        /// visit profile and logout pop up is displayed when click the three dot
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                context.push('/profile');
              } else if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('Profile'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      
      /// first check chat room is empty or not if chatRoom is empty display empty state others case display chat room data, like the chat of others user, display last message, 
      /// the _buildEmptyState widget create here cause it's only user here
      body: chatListState.chatRooms.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        itemCount: chatListState.chatRooms.length,
        itemBuilder: (context, index) {
          final chatRoom = chatListState.chatRooms[index];
          final otherUserId = chatRoom.participants
              .firstWhere((id) => id != authState.user!.uid);
          final otherUser = chatListState.users
              .where((user) => user.uid == otherUserId)
              .firstOrNull;

          if (otherUser == null) return const SizedBox.shrink();

          return GestureDetector(
            onTap: () {
              final chatRoomId = AppUtils.getChatRoomId(
                authState.user!.uid,
                otherUserId,
              );
              context.push('/chat/$chatRoomId', extra: otherUser);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Profile picture
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: otherUser.profilePictureUrl != null
                        ? CachedNetworkImageProvider(otherUser.profilePictureUrl!)
                        : null,
                    child: otherUser.profilePictureUrl == null
                        ? Text(
                      otherUser.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Name + Last Message
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherUser.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chatRoom.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Time + unread badge
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppUtils.formatTimestamp(chatRoom.lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      if (chatRoom.unreadCount[authState.user!.uid] != null &&
                          chatRoom.unreadCount[authState.user!.uid]! > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            chatRoom.unreadCount[authState.user!.uid].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),

        floatingActionButton: FloatingActionButton(
        onPressed: () => _showUsersDialog(context, authState.user!.uid),
        child: const Icon(Icons.add),
      ),
    );
  }
  /// the empty state it's displayed when no chat room is available 
  Widget _buildEmptyState() {
    return  Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          CustomText(text: "No Conversation Available", fontSize: 18,color: AppColors.greySix,),
          
          SizedBox(height: 8),
          CustomText(text: "Tap the + button to start a new chat", fontSize: 14,color: AppColors.greySix,),

        ],
      ),
    );
  }
  /// when user click the + button in a dialog they can see others user data, from here they can select others user and start conversation
  void _showUsersDialog(BuildContext context, String currentUserId) {
    final chatListState = ref.read(chatListViewModelProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Chat'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: chatListState.users.length,
            itemBuilder: (context, index) {
              final user = chatListState.users[index];
              if (user.uid == currentUserId) return const SizedBox.shrink();

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.profilePictureUrl != null
                      ? CachedNetworkImageProvider(user.profilePictureUrl!)
                      : null,
                  child: user.profilePictureUrl == null
                      ? Text(user.displayName[0].toUpperCase())
                      : null,
                ),
                title: Text(user.displayName),
                subtitle: Text(user.email),
                onTap: () {
                  Navigator.pop(context);
                  final chatRoomId = AppUtils.getChatRoomId(currentUserId, user.uid);
                  context.push('/chat/$chatRoomId', extra: user);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// when user click the logout before logout ask them or take consent from user they logout from app or not.

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authViewModelProvider.notifier).signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
