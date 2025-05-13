import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../theme/app_theme.dart';

class VideoTestScreen extends StatefulWidget {
  final File videoFile;

  const VideoTestScreen({Key? key, required this.videoFile}) : super(key: key);

  @override
  _VideoTestScreenState createState() => _VideoTestScreenState();
}

class _VideoTestScreenState extends State<VideoTestScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Check if file exists
      final exists = await widget.videoFile.exists();
      print('File exists: $exists');
      
      if (!exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'File does not exist';
        });
        return;
      }

      // Get file details
      final fileSize = await widget.videoFile.length();
      print('File size: $fileSize bytes');

      // Initialize controller with direct file path
      _controller = VideoPlayerController.file(widget.videoFile);
      
      print('Initializing video controller...');
      await _controller.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Video initialization timed out');
          throw Exception('Video initialization timed out');
        },
      );
      
      print('Video initialized successfully');
      print('Video size: ${_controller.value.size}');
      print('Video duration: ${_controller.value.duration}');
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error initializing video: $e');
      print('Stack trace: $stackTrace');
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Player Test'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video File Path:', 
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(widget.videoFile.path),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage.isNotEmpty)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Error',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_errorMessage),
                      ],
                    ),
                  ),
                )
              else if (_isInitialized)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _controller.value.isPlaying
                                  ? _controller.pause()
                                  : _controller.play();
                            });
                          },
                          icon: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          label: Text(
                            _controller.value.isPlaying ? 'Pause' : 'Play',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Video Details:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text('Duration: ${_controller.value.duration}'),
                            Text(
                                'Size: ${_controller.value.size.width.toInt()}x${_controller.value.size.height.toInt()}'),
                            Text('Aspect Ratio: ${_controller.value.aspectRatio}'),
                            Text('Position: ${_controller.value.position}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeVideo,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Loading Video'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 