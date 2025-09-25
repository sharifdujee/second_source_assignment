import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../services/firebase_auth_service.dart';
/// profile state and profile view model, it's use basically  for business logic that are related to user profile
class ProfileState {
  final bool isLoading;
  final UserModel? user;
  final bool isUpdating;
  final String? error;
  final String? successMessage;

  ProfileState({
    this.isLoading = false,
    this.user,
    this.isUpdating = false,
    this.error,
    this.successMessage,
  });

  ProfileState copyWith({
    bool? isLoading,
    UserModel? user,
    bool? isUpdating,
    String? error,
    String? successMessage,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
      successMessage: successMessage,
    );
  }
}


class ProfileViewModel extends StateNotifier<ProfileState> {
  final UserRepository _userRepository;
  final FirebaseAuthService _authService;

  ProfileViewModel({
    required UserRepository userRepository,
    required FirebaseAuthService authService,
  }) : _userRepository = userRepository,
        _authService = authService,
        super(ProfileState());
  /// load user profile use to load login user profile details, fetch the data based on userId
  Future<void> loadUserProfile() async {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      state = state.copyWith(isLoading: true);
      try {
        final user = await _userRepository.getUser(userId);
        state = state.copyWith(user: user, isLoading: false);
      } catch (e) {
        state = state.copyWith(error: e.toString(), isLoading: false);
      }
    }
  }
  /// this is update profile function the user can update their profile if they are authenticated
  Future<void> updateProfile({
    String? displayName,
    File? profilePicture,
  }) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    state = state.copyWith(isUpdating: true, error: null);

    try {
      Map<String, dynamic> updates = {};

      if (displayName != null && displayName.isNotEmpty) {
        updates['displayName'] = displayName;
        await _authService.updateUserName(displayName);
      }

      if (profilePicture != null) {
        final imageUrl = await _userRepository.uploadProfilePicture(
          profilePicture,
          userId,
        );
        if (imageUrl != null) {
          updates['profilePictureUrl'] = imageUrl;
        }
      }

      if (updates.isNotEmpty) {
        await _userRepository.updateUser(userId, updates);
        await loadUserProfile();
        state = state.copyWith(
          successMessage: 'Profile updated successfully',
          isUpdating: false,
        );
      } else {
        state = state.copyWith(isUpdating: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isUpdating: false);
    }
  }
}



