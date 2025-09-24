import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../services/fcm_service.dart';
import '../services/firebase_auth_service.dart';

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final FirebaseAuthService _authService;
  final UserRepository _userRepository;
  final FcmService _fcmService;

  AuthViewModel({
    required FirebaseAuthService authService,
    required UserRepository userRepository,
    required FcmService fcmService,
  }) : _authService = authService,
        _userRepository = userRepository,
        _fcmService = fcmService,
        super(AuthState()) {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        final userModel = await _userRepository.getUser(user.uid);
        if (userModel != null) {
          await _userRepository.updateUserStatus(user.uid, true);
        }
        state = state.copyWith(
          user: userModel,
          isAuthenticated: true,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          user: null,
          isAuthenticated: false,
          isLoading: false,
        );
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signInWithEmail(email, password);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signUp(String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authService.createUserWithEmail(email, password);
      if (result != null) {
        await _authService.updateDisplayName(displayName);

        final fcmToken = await _fcmService.getToken();

        final user = UserModel(
          uid: result.user!.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
          isOnline: true,
          fcmToken: fcmToken,
        );

        await _userRepository.createUser(user);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    if (state.user != null) {
      await _userRepository.updateUserStatus(state.user!.uid, false);
    }
    await _authService.signOut();
  }
}