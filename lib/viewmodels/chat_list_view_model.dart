import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_room.dart';
import '../models/user.dart';
import '../repositories/chat_repository.dart';
import '../repositories/user_repository.dart';

class ChatListState {
  final bool isLoading;
  final List<ChatRoomModel> chatRooms;
  final List<UserModel> users;
  final String? error;

  ChatListState({
    this.isLoading = false,
    this.chatRooms = const [],
    this.users = const [],
    this.error,
  });

  ChatListState copyWith({
    bool? isLoading,
    List<ChatRoomModel>? chatRooms,
    List<UserModel>? users,
    String? error,
  }) {
    return ChatListState(
      isLoading: isLoading ?? this.isLoading,
      chatRooms: chatRooms ?? this.chatRooms,
      users: users ?? this.users,
      error: error,
    );
  }
}

class ChatListViewModel extends StateNotifier<ChatListState> {
  final ChatRepository _chatRepository;
  final UserRepository _userRepository;

  ChatListViewModel({
    required ChatRepository chatRepository,
    required UserRepository userRepository,
  }) : _chatRepository = chatRepository,
        _userRepository = userRepository,
        super(ChatListState());

  void loadUserChatRooms(String userId) {
    _chatRepository.getUserChatRooms(userId).listen((chatRooms) {
      state = state.copyWith(chatRooms: chatRooms);
    });
  }

  void loadAllUsers() {
    _userRepository.getAllUsers().listen((users) {
      state = state.copyWith(users: users);
    });
  }
}
