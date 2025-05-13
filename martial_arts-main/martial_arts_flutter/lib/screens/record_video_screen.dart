import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import 'dart:io';

class RecordVideoScreen extends StatefulWidget {
  final String refVideoTitle;
  final String expertVideoUrl;

  const RecordVideoScreen({Key? key, required this.refVideoTitle, required this.expertVideoUrl}) : super(key: key);

  @override
  _RecordVideoScreenState createState() => _RecordVideoScreenState();
}

class _RecordVideoScreenState extends State<RecordVideoScreen> {
  File? _videoFile;
  bool _isLoading = false;
  bool _isVideoInitialized = false;
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _recordVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _recordVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        _cleanupControllers();
        
        setState(() {
          _videoFile = File(video.path);
          _isLoading = true;
          _isVideoInitialized = false;
        });

        // Initialize video controller for preview
        _videoController = VideoPlayerController.file(_videoFile!);
        await _videoController!.initialize();
        
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: true,
          looping: true,
          aspectRatio: _videoController!.value.aspectRatio,
          allowPlaybackSpeedChanging: true,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppTheme.primaryColor,
            handleColor: AppTheme.primaryColor,
            backgroundColor: Colors.grey.shade300,
            bufferedColor: AppTheme.primaryColor.withOpacity(0.5),
          ),
        );
        
        setState(() {
          _isVideoInitialized = true;
          _isLoading = false;
        });
      } else {
        // User canceled recording
        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error recording video: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      Navigator.pop(context);
    }
  }
  
  void _cleanupControllers() {
    _chewieController?.dispose();
    _chewieController = null;
    _videoController?.dispose();
    _videoController = null;
  }

  Future<void> _analyzeVideo() async {
    if (_videoFile == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$apiUrl/analyze'));
      request.fields['ref_video_title'] = widget.refVideoTitle;
      request.files.add(await http.MultipartFile.fromPath('user_video', _videoFile!.path));
      
      var response = await request.send();
      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/feedback',
          (route) => route.settings.name == '/lessons',
          arguments: {
            'feedbackData': await response.stream.bytesToString(),
            'userVideoFile': _videoFile,
            'expertVideoUrl': 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4', // Use a placeholder or fetch from API
          },
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error analyzing video. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing video: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Your Pose'),
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Card(
                    color: Colors.black87,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _videoFile != null && _isVideoInitialized && _chewieController != null
                          ? Chewie(controller: _chewieController!)
                          : Container(
                              color: Colors.grey[200],
                              child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.videocam,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Record a video of your pose',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_videoFile != null && _isVideoInitialized)
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _analyzeVideo,
                        icon: const Icon(Icons.compare_arrows),
                        label: const Text('Compare with Expert'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _recordVideo,
                              icon: const Icon(Icons.replay),
                              label: const Text('Record Again'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Go Back'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 