import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import '../theme/app_theme.dart';
import '../widgets/analysis_tab.dart';
import '../widgets/feedback_tab.dart';
import '../models/feedback_data.dart';
import '../services/feedback_service.dart';
import 'video_comparison_screen.dart';

class FeedbackScreen extends StatefulWidget {
  final String feedbackData;
  final String expertVideoUrl;
  final bool isFromHistory;
  final FeedbackData? savedFeedbackData;
  final File? userVideoFile;

  const FeedbackScreen({
    Key? key,
    required this.feedbackData,
    required this.expertVideoUrl,
    this.isFromHistory = false,
    this.savedFeedbackData,
    this.userVideoFile,
  }) : super(key: key);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with SingleTickerProviderStateMixin {
  late Map<String, dynamic> feedback;
  late TabController _tabController;
  File? userVideoFile;
  String? referenceVideoUrl;
  final FeedbackService _feedbackService = FeedbackService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _parseAndSetupFeedback();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _parseAndSetupFeedback() {
    try {
      feedback = json.decode(widget.feedbackData);
      // Use the user video file from widget
      userVideoFile = widget.userVideoFile;
      referenceVideoUrl = widget.expertVideoUrl;
    } catch (e) {
      print('Error parsing feedback data: $e');
      // Set defaults in case of error
      feedback = {'segments': [], 'feedback': 'Error parsing feedback data'};
      userVideoFile = widget.userVideoFile;
      referenceVideoUrl = widget.expertVideoUrl;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final segmentsList = feedback['segments'] as List<dynamic>? ?? [];
    final feedbackText =
        feedback['feedback'] as String? ?? 'No feedback available';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Feedback'),
        backgroundColor: AppTheme.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Analysis', icon: Icon(Icons.analytics)),
            Tab(text: 'Feedback', icon: Icon(Icons.comment)),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
        ),
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
        child: Column(
          children: [
            if (widget.userVideoFile != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoComparisonScreen(
                              expertVideoUrl: widget.expertVideoUrl,
                              userVideoFile: widget.userVideoFile,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.video_library),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap the video icon in the app bar to compare your performance with the expert demonstration.',
                              style: TextStyle(color: Colors.grey[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  AnalysisTab(
                    segments: segmentsList,
                    referenceVideoUrl: referenceVideoUrl ?? '',
                    userVideoFile: userVideoFile,
                  ),
                  FeedbackTab(feedbackText: feedbackText),
                ],
              ),
            ),
            if (widget.isFromHistory)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/lessons',
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Continue Training'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  ),
                ),
              ),
            if (!widget.isFromHistory)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/lessons',
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Continue Training'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 8),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveFeedback,
                      icon: const Icon(
                        Icons.save,
                        color: Colors.white,
                      ),
                      label: const Text('Save Feedback'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 8),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveFeedback() async {
    if (_isSaving) return;
    try {
      // print('Saving feedback with:');
      // print('Expert Video URL: ${widget.expertVideoUrl}');
      // print('User Video File: ${userVideoFile?.path}');

      // Create a copy of the user's video file in the app's storage
      String? savedUserVideoPath;
      if (userVideoFile != null) {
        final fileName = userVideoFile!.path.split('/').last;
        final newPath = '${userVideoFile!.parent.path}/saved_$fileName';
        await userVideoFile!.copy(newPath);
        savedUserVideoPath = newPath;
        print('Saved user video to: $savedUserVideoPath');
      }

      final feedbackData = FeedbackData(
        overallFeedback: feedback['feedback'] ?? '',
        segments: List<Map<String, dynamic>>.from(feedback['segments'] ?? []),
        timestamp: DateTime.now().toString(),
        expertVideoUrl: widget.expertVideoUrl,
        userVideoPath: savedUserVideoPath, // Use the saved video path
      );

      await _feedbackService.saveFeedback(feedbackData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback and videos saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving feedback and videos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving feedback: ${e.toString()}'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = true);
      }
    }
  }
}
