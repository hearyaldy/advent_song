// lib/presentation/auth/pages/profile_page.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/services/auth_service.dart';

/// A page where users can view and update their profile information,
/// manage their account, and access admin tools if they have the correct role.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isSavingPhoto = false; // To show a loading indicator on the avatar
  bool _isAdmin = false;
  Map<String, dynamic>? _userProfile;
  File? _profileImageFile;

  static const String _profileImageName = 'profile_photo.jpg';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadProfileImage();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  /// Fetches the user's profile data from the AuthService.
  /// Redirects to the login page if the user is not authenticated.
  Future<void> _loadUserProfile() async {
    if (!AuthService.isLoggedIn) {
      if (mounted) context.go('/login');
      return;
    }

    try {
      final profile = await AuthService.userProfile;
      final adminStatus = await AuthService.isAdmin;

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isAdmin = adminStatus;
          _nameController.text = profile?['name'] ?? '';
          _nicknameController.text = profile?['nickname'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Failed to load profile', isError: true);
      }
    }
  }

  /// Loads the profile image from the local device storage.
  Future<void> _loadProfileImage() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagePath = p.join(appDir.path, _profileImageName);
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        if (mounted) {
          // Invalidate the cache for the old image to ensure it reloads
          if (_profileImageFile != null) {
            FileImage(_profileImageFile!).evict();
          }
          setState(() {
            _profileImageFile = imageFile;
          });
        }
      }
    } catch (e) {
      _showMessage('Could not load profile image', isError: true);
    }
  }

  /// Opens the image gallery to let the user pick a new profile photo
  /// and saves it locally.
  ///
  /// **[FIX]** This method now reads the image data into memory as bytes
  /// before writing it to the app's local storage. This avoids file-copying
  /// errors. Also adds a loading state and more detailed error handling.
  Future<void> _pickAndSaveImage() async {
    if (_isSavingPhoto) return;
    setState(() => _isSavingPhoto = true);

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        if (mounted) setState(() => _isSavingPhoto = false);
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final newPath = p.join(appDir.path, _profileImageName);

      final imageBytes = await pickedFile.readAsBytes();
      final newImage = await File(newPath).writeAsBytes(imageBytes);

      if (mounted) {
        // Evict the old image from the cache before setting the new one
        if (_profileImageFile != null) {
          FileImage(_profileImageFile!).evict();
        }

        setState(() {
          _profileImageFile = newImage;
          _isSavingPhoto = false;
        });
        _showMessage('Profile photo updated!', isError: false);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating photo: $e');
      }
      if (mounted) {
        setState(() => _isSavingPhoto = false);
        _showMessage('Failed to update photo. Please check permissions.',
            isError: true);
      }
    }
  }

  /// Handles the profile update logic.
  /// After a successful update, it reloads the profile to ensure UI consistency.
  Future<void> _updateProfile() async {
    FocusScope.of(context).unfocus();
    setState(() => _isUpdating = true);

    final result = await AuthService.updateProfile(
      name: _nameController.text.trim(),
      nickname: _nicknameController.text.trim(),
    );

    if (result.isSuccess) {
      await _loadUserProfile();
      if (mounted) {
        _showMessage('Profile updated successfully', isError: false);
      }
    } else {
      if (mounted) {
        _showMessage(result.message, isError: true);
      }
    }

    if (mounted) {
      setState(() => _isUpdating = false);
    }
  }

  /// Shows a confirmation dialog and logs the user out.
  Future<void> _handleLogout() async {
    final confirm = await _showConfirmationDialog(
      title: 'Logout',
      content: 'Are you sure you want to logout?',
    );

    if (confirm == true) {
      // Also delete local image on logout to prevent it showing for another user
      await _deleteLocalImage();
      await AuthService.logout();
      if (mounted) context.go('/');
    }
  }

  /// Shows a confirmation dialog and deletes the user's account.
  Future<void> _handleDeleteAccount() async {
    final confirm = await _showConfirmationDialog(
      title: 'Delete Account',
      content:
          'Are you sure? This action is permanent and will remove all your data.',
      confirmText: 'Delete Account',
      isDestructive: true,
    );

    if (confirm == true) {
      final result = await AuthService.deleteAccount();
      if (mounted) {
        if (result.isSuccess) {
          await _deleteLocalImage();
          _showMessage('Account deleted successfully', isError: false);
          context.go('/');
        } else {
          _showMessage(result.message, isError: true);
        }
      }
    }
  }

  /// Deletes the locally stored profile image.
  Future<void> _deleteLocalImage() async {
    try {
      if (_profileImageFile != null && await _profileImageFile!.exists()) {
        await _profileImageFile!.delete();
        if (mounted) {
          setState(() {
            _profileImageFile = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to delete local profile image: $e');
    }
  }

  /// Displays a message to the user in a floating SnackBar.
  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!AuthService.isLoggedIn) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Login'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              tooltip: 'Logout'),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 32),
            _buildSectionTitle(
                context, 'Edit Information', Icons.edit_note_rounded),
            const SizedBox(height: 16),
            _buildProfileForm(context),
            const SizedBox(height: 32),
            if (_isAdmin) _buildAdminTools(context),
            _buildSectionTitle(
                context, 'Danger Zone', Icons.warning_amber_rounded),
            const SizedBox(height: 12),
            _buildDangerZone(context),
          ],
        ),
      ),
    );
  }

  /// Builds the main content of the profile form.
  Widget _buildProfileForm(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nicknameController,
          decoration: InputDecoration(
            labelText: 'Nickname',
            prefixIcon: const Icon(Icons.tag_faces_rounded),
            helperText: 'How you would like to be called?',
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isUpdating ? null : _updateProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isUpdating
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3))
              : const Text('Save Changes'),
        ),
      ],
    );
  }

  /// Builds the header section with the user's avatar and name.
  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final name = _userProfile?['name'] as String? ?? '';
    final email = _userProfile?['email'] as String? ?? 'No email';

    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e[0]).take(2).join()
        : (email.isNotEmpty ? email[0] : 'G');

    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: _profileImageFile != null
                  ? FileImage(_profileImageFile!)
                  : null,
              child: _profileImageFile == null
                  ? Text(
                      initials.toUpperCase(),
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(color: colorScheme.onPrimaryContainer),
                    )
                  : null,
            ),
            // Show loading indicator when saving a new photo
            if (_isSavingPhoto) const CircularProgressIndicator(),
            // Don't show the edit button while saving
            if (!_isSavingPhoto)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndSaveImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: colorScheme.surface, width: 2)),
                    child: Icon(Icons.edit,
                        color: colorScheme.onPrimary, size: 16),
                  ),
                ),
              )
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isNotEmpty ? name : 'Guest',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        if (_isAdmin) ...[
          const SizedBox(width: 8),
          const Icon(Icons.shield_rounded, color: Colors.orange, size: 28),
        ]
      ],
    );
  }

  /// Builds the section for administrator-only actions.
  Widget _buildAdminTools(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
            context, 'Admin Tools', Icons.admin_panel_settings_rounded),
        const SizedBox(height: 12),
        _buildActionTile(
          context,
          icon: Icons.article_rounded,
          iconColor: Colors.orange,
          title: 'Sermon Management',
          subtitle: 'Add, edit, or delete sermons',
          onTap: () => context.go('/admin/sermons'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  /// Builds the section for dangerous, irreversible actions.
  Widget _buildDangerZone(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withOpacity(0.5)),
      ),
      child: ListTile(
        leading: Icon(Icons.delete_forever_rounded, color: colorScheme.error),
        title: Text('Delete Account',
            style: TextStyle(
                color: colorScheme.error, fontWeight: FontWeight.bold)),
        subtitle: const Text('This action is permanent'),
        onTap: _handleDeleteAccount,
      ),
    );
  }

  /// A generic builder for section titles with an icon.
  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleLarge),
      ],
    );
  }

  /// A generic builder for clickable list tiles used for actions.
  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  /// A generic confirmation dialog.
  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    String confirmText = 'Confirm',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
