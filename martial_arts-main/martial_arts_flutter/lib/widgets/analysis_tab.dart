import 'dart:io';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnalysisTab extends StatefulWidget {
  final List<dynamic> segments;
  final String referenceVideoUrl;
  final File? userVideoFile;

  const AnalysisTab({
    Key? key,
    required this.segments,
    required this.referenceVideoUrl,
    this.userVideoFile,
  }) : super(key: key);

  @override
  _AnalysisTabState createState() => _AnalysisTabState();
}

class _AnalysisTabState extends State<AnalysisTab> {
  Color _getScoreColor(double score) {
    if (score < 5) {
      return Colors.green;
    } else if (score < 10) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }

  Widget _buildSegmentDetails(
      BuildContext context, Map<String, dynamic> segment) {
    final segmentText = segment['segment_text'] as String;
    final lines = segmentText.split('\n');

    if (lines.isEmpty) return const SizedBox.shrink();

    // Extract average difference from the first line
    final averageLine = lines[0];
    double averageAngle = 0.0;
    try {
      final match = RegExp(r'Average angle difference: (\d+\.\d+)')
          .firstMatch(averageLine);
      if (match != null) {
        averageAngle = double.parse(match.group(1) ?? '0.0');
      }
    } catch (e) {
      print('Error parsing average angle: $e');
    }

    // Build widgets for each joint angle
    final List<Widget> angleWidgets = [];
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        // Parse the line pattern: "- Joint Name: XX.XX degrees (Description)"
        final match =
            RegExp(r'- (.*?): (\d+\.\d+) degrees \((.*?)\)').firstMatch(line);
        if (match != null) {
          final jointName = match.group(1) ?? '';
          final angleValue = double.parse(match.group(2) ?? '0.0');
          final description = match.group(3) ?? '';

          angleWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        jointName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          color: _getScoreColor(angleValue),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 1.0 - (angleValue / 20.0).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      color: _getScoreColor(angleValue),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${angleValue.toStringAsFixed(1)}° difference',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        print('Error parsing angle line: $e');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.insights,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Overall Accuracy',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Average Angle Difference: ${averageAngle.toStringAsFixed(1)}°',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 1.0 - (averageAngle / 20.0).clamp(0.0, 1.0),
                    minHeight: 12,
                    backgroundColor: Colors.grey[300],
                    color: _getScoreColor(averageAngle),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  averageAngle < 5
                      ? 'Excellent form! Your pose matches the expert demonstration very well.'
                      : averageAngle < 10
                          ? 'Good form. Some minor improvements could be made to match the expert pose better.'
                          : 'Your form needs improvement. Try to match the expert pose more closely.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Detailed Angle',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...angleWidgets,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentTile(
      BuildContext context, int index, Map<String, dynamic> segment) {
    final expertStartTime = segment['expert_start_time'] as int? ?? 0;
    final expertEndTime = segment['expert_end_time'] as int? ?? 0;
    final userStartTime = segment['usr_start_time'] as int? ?? 0;
    final userEndTime = segment['usr_end_time'] as int? ?? 0;


    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        title: Text(
          'Segment ${index + 1} \n '
              'Expert video: (${expertStartTime}s - ${expertEndTime}s)\n '
              'Your video: (${userStartTime}s - ${userEndTime}s)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        subtitle: Text('Tap to expand and see detailed analysis'),
        leading: const Icon(Icons.video_library),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          _buildSegmentDetails(context, segment),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Segment Analysis',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Expand each segment to see detailed analysis and video comparison',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 24),

          // Build expansion tile for each segment
          ...List.generate(
              widget.segments.length,
              (index) => _buildSegmentTile(context, index,
                  widget.segments[index] as Map<String, dynamic>)),
        ],
      ),
    );
  }
}
