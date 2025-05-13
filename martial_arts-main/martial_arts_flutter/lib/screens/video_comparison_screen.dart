import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:io';
import '../theme/app_theme.dart';

class VideoComparisonScreen extends StatefulWidget {
  final String expertVideoUrl;
  final File? userVideoFile;

  const VideoComparisonScreen({
    Key? key,
    required this.expertVideoUrl,
    required this.userVideoFile,
  }) : super(key: key);

  @override
  _VideoComparisonScreenState createState() => _VideoComparisonScreenState();
}

class _VideoComparisonScreenState extends State<VideoComparisonScreen> {
  VideoPlayerController? _expertController;
  VideoPlayerController? _userController;
  ChewieController? _expertChewieController;
  ChewieController? _userChewieController;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedVideo = 0; // 0 for both, 1 for expert, 2 for user

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Initialize expert video controller
      _expertController = VideoPlayerController.networkUrl(Uri.parse(widget.expertVideoUrl));
      await _expertController!.initialize();

      // Initialize user video controller if available
      if (widget.userVideoFile != null) {
        _userController = VideoPlayerController.file(widget.userVideoFile!);
        await _userController!.initialize();
      }

      // Create Chewie controllers
      _expertChewieController = ChewieController(
        videoPlayerController: _expertController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _expertController!.value.aspectRatio,
        allowPlaybackSpeedChanging: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primaryColor,
          handleColor: AppTheme.primaryColor,
          backgroundColor: Colors.grey.shade300,
          bufferedColor: AppTheme.primaryColor.withOpacity(0.5),
        ),
      );

      if (_userController != null) {
        _userChewieController = ChewieController(
          videoPlayerController: _userController!,
          autoPlay: false,
          looping: false,
          aspectRatio: _userController!.value.aspectRatio,
          allowPlaybackSpeedChanging: true,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppTheme.primaryColor,
            handleColor: AppTheme.primaryColor,
            backgroundColor: Colors.grey.shade300,
            bufferedColor: AppTheme.primaryColor.withOpacity(0.5),
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing video controllers: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading videos: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _expertChewieController?.dispose();
    _userChewieController?.dispose();
    _expertController?.dispose();
    _userController?.dispose();
    super.dispose();
  }

  Widget _buildVideoPlayer(ChewieController? controller, String title, {bool showBorder = false}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: showBorder ? BorderSide(
          color: AppTheme.primaryColor,
          width: 2,
        ) : BorderSide.none,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  title.contains('Expert') ? Icons.star : Icons.person,
                  color: title.contains('Expert') ? Colors.amber : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: AspectRatio(
              aspectRatio: controller?.videoPlayerController.value.aspectRatio ?? 16/9,
              child: Container(
                color: Colors.black,
                child: controller != null
                    ? Chewie(controller: controller)
                    : const Center(
                        child: Text(
                          'Video not available',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildViewOption(0, 'Both Videos'),
            _buildViewOption(1, 'Expert Only'),
            _buildViewOption(2, 'Your Video'),
          ],
        ),
      ),
    );
  }

  Widget _buildViewOption(int value, String label) {
    final isSelected = _selectedVideo == value;
    return InkWell(
      onTap: () => setState(() => _selectedVideo = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Comparison'),
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
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      _buildViewSelector(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (_selectedVideo == 0 || _selectedVideo == 1)
                                _buildVideoPlayer(_expertChewieController, 'Expert Demonstration', showBorder: _selectedVideo == 1),
                              if (_selectedVideo == 0)
                                const SizedBox(height: 16),
                              if (_selectedVideo == 0 || _selectedVideo == 2)
                                _buildVideoPlayer(_userChewieController, 'Your Performance', showBorder: _selectedVideo == 2),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
