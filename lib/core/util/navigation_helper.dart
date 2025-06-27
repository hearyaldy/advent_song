// lib/core/utils/navigation_helper.dart - NEW UTILITY FILE
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';

class NavigationHelper {
  /// Safely navigate to a collection, with validation
  static void goToCollection(BuildContext context, String collectionId,
      {bool search = false}) {
    if (!AppConstants.collections.containsKey(collectionId)) {
      debugPrint('Invalid collection ID: $collectionId');
      _showErrorSnackBar(context, 'Collection "$collectionId" not found');
      return;
    }

    final path = search
        ? '/collection/$collectionId?search=true'
        : '/collection/$collectionId';
    context.go(path);
  }

  /// Safely navigate to lyrics page, with validation
  static void goToLyrics(
      BuildContext context, String collectionId, String songId) {
    if (!AppConstants.collections.containsKey(collectionId)) {
      debugPrint('Invalid collection ID: $collectionId');
      _showErrorSnackBar(context, 'Collection "$collectionId" not found');
      return;
    }

    if (songId.isEmpty) {
      debugPrint('Empty song ID');
      _showErrorSnackBar(context, 'Invalid song');
      return;
    }

    context.go('/lyrics/$collectionId/$songId');
  }

  /// Safely navigate back with fallback
  static void goBack(BuildContext context, {String fallbackRoute = '/'}) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallbackRoute);
    }
  }

  /// Show error message to user
  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Validate if collection exists
  static bool isValidCollection(String collectionId) {
    return AppConstants.collections.containsKey(collectionId);
  }

  /// Get first available collection as fallback
  static String getDefaultCollection() {
    return AppConstants.collections.keys.first;
  }

  /// Get safe collection ID with fallback
  static String getSafeCollectionId(String? collectionId) {
    if (collectionId != null &&
        AppConstants.collections.containsKey(collectionId)) {
      return collectionId;
    }
    return getDefaultCollection();
  }
}
