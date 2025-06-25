// lib/presentation/admin/pages/admin_login_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/auth_service.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoggingIn = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage('Please enter email and password', isError: true);
      return;
    }

    setState(() {
      _isLoggingIn = true;
    });

    final result = await AuthService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() {
      _isLoggingIn = false;
    });

    if (result.isSuccess) {
      // Check if user is admin
      final isAdmin = await AuthService.isAdmin;
      if (isAdmin) {
        context.go('/admin/sermons');
      } else {
        await AuthService.logout();
        _showMessage('Access denied. Admin privileges required.',
            isError: true);
      }
    } else {
      _showMessage(result.message, isError: true);
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showMessage('Please enter your email address first', isError: true);
      return;
    }

    final result =
        await AuthService.resetPassword(_emailController.text.trim());

    if (result.isSuccess) {
      _showMessage('Password reset email sent. Check your inbox.',
          isError: false);
    } else {
      _showMessage(result.message, isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange,
                        Colors.deepOrange,
                      ],
                    ),
                  ),
                ),
                title: const Text(
                  'Admin Login',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(24.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 40),

                  // Icon and description
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.orange,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Administrator Access',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Login to manage sermons and app content',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Login Form
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Login Credentials',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'admin@church.com',
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(_showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _showPassword = !_showPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: !_showPassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleLogin(),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _handleForgotPassword,
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoggingIn ? null : _handleLogin,
                              icon: _isLoggingIn
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.login),
                              label: Text(_isLoggingIn
                                  ? 'Logging in...'
                                  : 'Login as Admin'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Warning
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: Colors.amber,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Access Only',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'This area is restricted to authorized administrators only.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
