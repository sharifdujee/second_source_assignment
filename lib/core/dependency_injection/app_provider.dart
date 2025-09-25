import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/chat_repository.dart';
import '../../repositories/user_repository.dart';
import '../../services/fcm_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/chat_list_view_model.dart';
import '../../viewmodels/profile_view_model.dart';

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService();
});

// Repositories
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});



final chatListViewModelProvider = StateNotifierProvider<ChatListViewModel, ChatListState>((ref) {
  return ChatListViewModel(
    chatRepository: ref.watch(chatRepositoryProvider),
    userRepository: ref.watch(userRepositoryProvider),
  );
});

final profileViewModelProvider = StateNotifierProvider<ProfileViewModel, ProfileState>((ref) {
  return ProfileViewModel(
    userRepository: ref.watch(userRepositoryProvider),
    authService: ref.watch(firebaseAuthServiceProvider),
  );
});
final authViewModelProvider = ChangeNotifierProvider<AuthViewModel>((ref) {
  return AuthViewModel(
    authService: ref.read(firebaseAuthServiceProvider),
    userRepository: ref.read(userRepositoryProvider),
    fcmService: ref.read(fcmServiceProvider),
  );
});

