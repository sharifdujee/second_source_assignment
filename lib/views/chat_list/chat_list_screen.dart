import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_application/core/constants/app_color.dart';
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
    final authState = ref.watch(authViewModelProvider);
    final chatListState = ref.watch(chatListViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
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

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: otherUser.profilePictureUrl != null
                  ? CachedNetworkImageProvider(otherUser.profilePictureUrl!)
                  : null,
              child: otherUser.profilePictureUrl == null
                  ? Text(otherUser.displayName[0].toUpperCase())
                  : null,
            ),
            title: Text(otherUser.displayName),
            subtitle: Text(
              chatRoom.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppUtils.formatTimestamp(chatRoom.lastMessageTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (chatRoom.unreadCount[authState.user!.uid] != null &&
                    chatRoom.unreadCount[authState.user!.uid]! > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(6),
                    decoration:  BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      chatRoom.unreadCount[authState.user!.uid].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
              final chatRoomId = AppUtils.getChatRoomId(
                authState.user!.uid,
                otherUserId,
              );
              context.push('/chat/$chatRoomId', extra: otherUser);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUsersDialog(context, authState.user!.uid),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the + button to start a new chat',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

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
