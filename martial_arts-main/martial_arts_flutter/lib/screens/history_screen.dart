import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import '../models/feedback_data.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import 'feedback_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FeedbackService _feedbackService = FeedbackService();
  List<FeedbackData> _feedbackHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedbackHistory();
  }

  Future<void> _loadFeedbackHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _feedbackService.getSavedFeedback();
      setState(() {
        _feedbackHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading feedback history: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading feedback history')),
        );
      }
    }
  }

  void _openFeedbackDetails(FeedbackData feedback) {
    try {
      // Create the feedback data map
      final feedbackMap = {
        'feedback': feedback.overallFeedback,
        'segments': feedback.segments,
      };

      // Convert the map to a JSON string
      final feedbackDataString = json.encode(feedbackMap);

      // Create a File object from the saved video path if it exists
      File? userVideoFile;
      if (feedback.userVideoPath != null) {
        userVideoFile = File(feedback.userVideoPath!);
        // Verify if the file exists
        if (!userVideoFile.existsSync()) {
          print(
              'Warning: Saved video file not found at ${feedback.userVideoPath}');
          userVideoFile = null;
        }
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FeedbackScreen(
            feedbackData: feedbackDataString,
            expertVideoUrl: feedback.expertVideoUrl ?? '',
            userVideoFile: userVideoFile,
            isFromHistory: true,
            savedFeedbackData: feedback,
          ),
        ),
      );
    } catch (e) {
      print('Error opening feedback details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening feedback details: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training History'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.backgroundColor.withOpacity(0.8),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _feedbackHistory.isEmpty
                ? const Center(
                    child: Text(
                      'No training history yet',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _feedbackHistory.length,
                    itemBuilder: (context, index) {
                      final feedback = _feedbackHistory[index];
                      // set date format MMM d, yyyy hh:mm a
                      final formattedDate = DateFormat('MMM d, yyyy hh:mm a')
                          .format(DateTime.parse(feedback.timestamp));

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () => _openFeedbackDetails(feedback),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Training Session',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  feedback.overallFeedback,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (feedback.userVideoPath != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.video_library,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Video available',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
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
                    },
                  ),
      ),
    );
  }
}
