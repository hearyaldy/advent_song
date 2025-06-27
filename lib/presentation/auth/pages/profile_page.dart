// lib/presentation/auth/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isAdmin = false;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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
      // Reload the user profile to ensure all parts of the app
      // (including AuthService.userName) have the fresh data.
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
          _showMessage('Account deleted successfully', isError: false);
          context.go('/');
        } else {
          _showMessage(result.message, isError: true);
        }
      }
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

    // This handles the case where the widget rebuilds after logout.
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
            // This ensures the back button always has a place to go.
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/'); // Fallback to home page
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
    final initials = AuthService.userName.isNotEmpty
        ? AuthService.userName.split(' ').map((e) => e[0]).take(2).join()
        : 'G';

    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: colorScheme.primary,
          child: Text(
            initials.toUpperCase(),
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: colorScheme.onPrimary),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _nameController.text.isNotEmpty
                    ? _nameController.text
                    : 'Guest',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _userProfile?['email'] ?? 'No email',
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
