// lib/core/services/sermon_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SermonService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'sermons';

  // Get all sermons
  static Stream<List<Map<String, dynamic>>> getSermons() {
    return _firestore
        .collection(_collection)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Add new sermon (admin only)
  static Future<bool> addSermon({
    required String title,
    required String pastor,
    required DateTime date,
    required String series,
    required String description,
    required int duration, // in minutes
    List<String> tags = const [],
    String? audioUrl,
    String? videoUrl,
  }) async {
    try {
      await _firestore.collection(_collection).add({
        'title': title,
        'pastor': pastor,
        'date': Timestamp.fromDate(date),
        'series': series,
        'description': description,
        'duration': duration,
        'tags': tags,
        'audioUrl': audioUrl,
        'videoUrl': videoUrl,
        'hasAudio': audioUrl != null && audioUrl.isNotEmpty,
        'hasVideo': videoUrl != null && videoUrl.isNotEmpty,
        'createdAt': FieldValue.serverTimestamp(),
        'isNew': true,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update sermon (admin only)
  static Future<bool> updateSermon(
      String sermonId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(sermonId).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete sermon (admin only)
  static Future<bool> deleteSermon(String sermonId) async {
    try {
      await _firestore.collection(_collection).doc(sermonId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Mark sermon as not new
  static Future<void> markAsViewed(String sermonId) async {
    try {
      await _firestore.collection(_collection).doc(sermonId).update({
        'isNew': false,
      });
    } catch (e) {
      // Ignore errors for this non-critical operation
    }
  }
}
