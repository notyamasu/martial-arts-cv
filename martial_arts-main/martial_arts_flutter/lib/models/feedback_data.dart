import 'dart:convert';

class FeedbackData {
  final String overallFeedback;
  final List<Map<String, dynamic>> segments;
  final String timestamp;
  final String? expertVideoUrl;
  final String? userVideoPath;

  FeedbackData({
    required this.overallFeedback,
    required this.segments,
    required this.timestamp,
    this.expertVideoUrl,
    this.userVideoPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'overallFeedback': overallFeedback,
      'segments': segments,
      'timestamp': timestamp,
      'expertVideoUrl': expertVideoUrl,
      'userVideoPath': userVideoPath,
    };
  }

  factory FeedbackData.fromJson(Map<String, dynamic> json) {
    return FeedbackData(
      overallFeedback: json['overallFeedback'],
      segments: List<Map<String, dynamic>>.from(json['segments']),
      timestamp: json['timestamp'],
      expertVideoUrl: json['expertVideoUrl'],
      userVideoPath: json['userVideoPath'],
    );
  }
}
