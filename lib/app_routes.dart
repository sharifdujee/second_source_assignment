
import 'package:chat_application/views/auth/login_screen.dart';
import 'package:chat_application/views/auth/registration_screen.dart';
import 'package:chat_application/views/chat_list/chat_list_screen.dart';
import 'package:chat_application/views/chat_room/chat_room_screen.dart';
import 'package:chat_application/views/profile/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/dependency_injection/app_provider.dart';

import 'models/user.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;

// Show loading screen during auth state check
      if (isLoading) return null;

// Redirect to login if not authenticated
      if (!isAuthenticated && state.uri.toString() != '/register') {
        return '/login';
      }

// Redirect to chat list if authenticated and trying to access auth pages
      if (isAuthenticated && (state.uri.toString() == '/login' || state.uri.toString() == '/register')) {
        return '/chat-list';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) =>  LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/chat-list',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:chatRoomId',
        builder: (context, state) {
          final chatRoomId = state.pathParameters['chatRoomId']!;
          final otherUser = state.extra as UserModel;
          return ChatRoomScreen(
            chatRoomId: chatRoomId,
            otherUser: otherUser,
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});