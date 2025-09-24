
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_application/core/constants/app_paddings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/dependency_injection/app_provider.dart';
import '../../core/utils/app_utils.dart';
import '../../main.dart';
import '../../viewmodels/profile_view_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_indicator.dart';
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileViewModelProvider.notifier).loadUserProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileViewModelProvider);

    ref.listen(profileViewModelProvider, (previous, next) {
      if (next?.error != null) {
        AppUtils.showSnackBar(context, next.error!, isError: true);
      }
      if (next.successMessage != null) {
        AppUtils.showSnackBar(context, next.successMessage!);
      }
    });

    if (profileState.isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Loading profile...'),
      );
    }

    if (profileState.user != null && _nameController.text.isEmpty) {
      _nameController.text = profileState.user!.displayName;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: AppPaddings.defaultPadding,
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfilePicture(profileState),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _nameController,
              hintText: 'Display Name',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: TextEditingController(text: profileState.user?.email ?? ''),
              hintText: 'Email',
              readOnly: true,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Update Profile',
              isLoading: profileState.isUpdating,
              onPressed: _updateProfile,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Logout',
              backgroundColor: Colors.red,
              onPressed: () {
                ref.read(authViewModelProvider.notifier).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture(ProfileState profileState) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: ClipOval(
          child: _selectedImage != null
              ? Image.file(_selectedImage!, fit: BoxFit.cover)
              : profileState.user?.profilePictureUrl != null
              ? CachedNetworkImage(
            imageUrl: profileState.user!.profilePictureUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => _buildDefaultAvatar(profileState),
          )
              : _buildDefaultAvatar(profileState),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(ProfileState profileState) {
    return Container(
      color: Colors.grey[200],
      child: profileState.user != null
          ? Center(
        child: Text(
          profileState.user!.displayName[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      )
          : const Icon(
        Icons.person,
        size: 48,
        color: Colors.grey,
      ),
    );
  }

  void _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _updateProfile() {
    if (_nameController.text.trim().isEmpty) {
      AppUtils.showSnackBar(context, 'Please enter your name', isError: true);
      return;
    }

    ref.read(profileViewModelProvider.notifier).updateProfile(
      displayName: _nameController.text.trim(),
      profilePicture: _selectedImage,
    );

    setState(() {
      _selectedImage = null;
    });
  }
}