import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/video_model.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lessons_screen.dart';
import 'screens/pose_detail_screen.dart';
import 'screens/record_video_screen.dart';
import 'screens/gallery_video_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/history_screen.dart';
import 'constants/app_constants.dart';
import 'theme/app_theme.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appName,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/lessons': (context) => const LessonsScreen(),
        '/history': (context) => const HistoryScreen(),
        '/poseDetail': (context) {
          final video =
              ModalRoute.of(context)!.settings.arguments as VideoModel;
          return PoseDetailScreen(video: video);
        },
        '/recordVideo': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return RecordVideoScreen(
            refVideoTitle: args['refVideoTitle'],
            expertVideoUrl: args['expertVideoUrl'],
          );
        },
        '/galleryVideo': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return GalleryVideoScreen(
            refVideoTitle: args['refVideoTitle'] as String,
            expertVideoUrl: args['expertVideoUrl'] as String,
          );
        },
        '/feedback': (context) {
          final feedbackData = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return FeedbackScreen(
            feedbackData: feedbackData['feedbackData'] as String,
            userVideoFile: feedbackData['userVideoFile'] as File?,
            expertVideoUrl: feedbackData['expertVideoUrl'] as String,
          );
        },

      },
    );
  }
}
