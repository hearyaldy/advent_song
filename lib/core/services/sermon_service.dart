// lib/core/services/sermon_service.dart
import 'package:firebase_database/firebase_database.dart';

class SermonService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final DatabaseReference _sermonsRef = _database.ref().child('sermons');

  // Get all sermons
  static Stream<List<Map<String, dynamic>>> getSermons() {
    return _sermonsRef.orderByChild('date').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <Map<String, dynamic>>[];

      return data.entries.map((entry) {
        final sermonData = Map<String, dynamic>.from(entry.value as Map);
        sermonData['id'] = entry.key;
        // Convert timestamp to DateTime if needed
        if (sermonData['date'] is int) {
          sermonData['date'] =
              DateTime.fromMillisecondsSinceEpoch(sermonData['date']);
        }
        return sermonData;
      }).toList()
        ..sort(
            (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
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
      await _sermonsRef.push().set({
        'title': title,
        'pastor': pastor,
        'date': date.millisecondsSinceEpoch,
        'series': series,
        'description': description,
        'duration': duration,
        'tags': tags,
        'audioUrl': audioUrl ?? '',
        'videoUrl': videoUrl ?? '',
        'hasAudio': audioUrl != null && audioUrl.isNotEmpty,
        'hasVideo': videoUrl != null && videoUrl.isNotEmpty,
        'createdAt': ServerValue.timestamp,
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
      // Convert DateTime to timestamp if present
      if (data['date'] is DateTime) {
        data['date'] = (data['date'] as DateTime).millisecondsSinceEpoch;
      }
      await _sermonsRef.child(sermonId).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete sermon (admin only)
  static Future<bool> deleteSermon(String sermonId) async {
    try {
      await _sermonsRef.child(sermonId).remove();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Mark sermon as not new
  static Future<void> markAsViewed(String sermonId) async {
    try {
      await _sermonsRef.child(sermonId).update({
        'isNew': false,
      });
    } catch (e) {
      // Ignore errors for this non-critical operation
    }
  }
}
