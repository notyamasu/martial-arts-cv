import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feedback_data.dart';

class FeedbackService {
  static const String _feedbackKey = 'saved_feedback';

  Future<void> saveFeedback(FeedbackData feedback) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFeedback = await getSavedFeedback();
      
      // Add the new feedback at the beginning of the list
      savedFeedback.insert(0, feedback);
      
      // Limit the number of saved feedback entries to prevent excessive storage usage
      if (savedFeedback.length > 50) {
        savedFeedback.removeLast();
      }

      final jsonList = savedFeedback.map((f) => f.toJson()).toList();
      await prefs.setString(_feedbackKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving feedback: $e');
      throw Exception('Failed to save feedback');
    }
  }

  Future<List<FeedbackData>> getSavedFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_feedbackKey);

    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => FeedbackData.fromJson(json)).toList();
    } catch (e) {
      print('Error getting saved feedback: $e');
      return [];
    }
  }

  Future<void> clearAllFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_feedbackKey);
  }
}
