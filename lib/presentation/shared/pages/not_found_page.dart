// TODO Implement this library.
// lib/presentation/shared/pages/not_found_page.dart - NEW FILE
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundPage extends StatelessWidget {
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const NotFoundPage({
    super.key,
    this.title = 'Page Not Found',
    this.message = 'The page you are looking for does not exist.',
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: colorScheme.surface,
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
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Column(
                children: [
                  if (onAction != null && actionText != null)
                    FilledButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.home_rounded),
                      label: Text(actionText!),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  if (onAction != null && actionText != null)
                    const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Go Back'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Additional Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'If this error persists, please restart the app',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
