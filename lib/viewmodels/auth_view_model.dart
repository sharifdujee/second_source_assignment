

import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../services/fcm_service.dart';
import '../services/firebase_auth_service.dart';
import 'package:flutter/foundation.dart';

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

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuthService _authService;
  final UserRepository _userRepository;
  final FcmService _fcmService;

  UserModel? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthViewModel({
    required FirebaseAuthService authService,
    required UserRepository userRepository,
    required FcmService fcmService,
  })  : _authService = authService,
        _userRepository = userRepository,
        _fcmService = fcmService {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        final userModel = await _userRepository.getUser(firebaseUser.uid);
        if (userModel != null) {
          await _userRepository.updateUserStatus(firebaseUser.uid, true);
        }
        _user = userModel;
        _isAuthenticated = true;
        _isLoading = false;
      } else {
        _user = null;
        _isAuthenticated = false;
        _isLoading = false;
      }
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithEmail(email, password);
      // authStateChanges stream will update the user automatically
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String displayName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.createUserWithEmail(email, password);
      if (result != null) {
        await _authService.updateDisplayName(displayName);

        final fcmToken = await _fcmService.getToken();

        final newUser = UserModel(
          uid: result.user!.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
          isOnline: true,
          fcmToken: fcmToken,
        );

        await _userRepository.createUser(newUser);
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (_user != null) {
      await _userRepository.updateUserStatus(_user!.uid, false);
    }
    await _authService.signOut();
    // Stream listener will handle resetting state
  }
}
