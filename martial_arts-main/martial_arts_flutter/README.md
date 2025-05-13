# Martial Arts Training Assistant - Mobile App

A Flutter-based mobile application that provides an intuitive interface for martial arts training, video recording, and feedback visualization. This app works in conjunction with the backend service to help users improve their martial arts techniques through video analysis and real-time feedback.

## Features

### 1. Video-Based Training
- Record training sessions
- Select videos from gallery
- Upload videos for analysis
- Side-by-side video comparison with expert demonstrations

### 2. Performance Analysis
- Real-time feedback display
- Angle analysis visualization
- Segment-by-segment comparison
- Progress tracking

### 3. Training History
- Save and manage feedback
- Review past performances
- Track improvement over time
- Export training data

## Project Structure

```
./
├── lib/
│   ├── constants/         # App-wide constants and configurations
│   │   ├── colors.dart
│   │   └── theme.dart
│   │
│   ├── models/           # Data models
│   │   ├── feedback_data.dart
│   │   └── video_data.dart
│   │
│   ├── screens/          # App screens
│   │   ├── home_screen.dart
│   │   ├── feedback_screen.dart
│   │   ├── history_screen.dart
│   │   ├── video_comparison_screen.dart
│   │   └── gallery_video_screen.dart
│   │
│   ├── services/         # Business logic and API services
│   │   ├── feedback_service.dart
│   │   └── video_service.dart
│   │
│   ├── theme/           # App theming
│   │   └── app_theme.dart
│   │
│   ├── widgets/         # Reusable UI components
│   │   ├── video_player_widget.dart
│   │   ├── feedback_tab.dart
│   │   └── analysis_tab.dart
│   │
│   └── main.dart        # App entry point
│
├── android/             # Android-specific files
├── ios/                # iOS-specific files
├── pubspec.yaml        # Dependencies and assets
└── test/              # Unit and widget tests
```

## Key Components

### 1. Screens
- `HomeScreen`: Main navigation and video recording
- `FeedbackScreen`: Display analysis results with tabs
- `HistoryScreen`: Past training sessions
- `VideoComparisonScreen`: Side-by-side video comparison
- `GalleryVideoScreen`: Video selection from gallery

### 2. Services
- `FeedbackService`: Manages feedback data storage
- `VideoService`: Handles video processing and API communication

### 3. Models
- `FeedbackData`: Structured feedback information
- `VideoData`: Video metadata and processing status

### 4. Widgets
- `VideoPlayerWidget`: Custom video player with Chewie
- `FeedbackTab`: Displays textual feedback
- `AnalysisTab`: Shows angle analysis and comparisons



## Dependencies

Main packages used in the project:
- `video_player`: Video playback
- `chewie`: Enhanced video player UI
- `image_picker`: Media selection
- `http`: API communication
- `provider`: State management
- `shared_preferences`: Local storage
- `firebase_core`: Firebase integration

## Features in Detail

### 1. Video Comparison
- Split screen view of expert and user videos
- Synchronized playback controls
- Frame-by-frame navigation
- Angle overlay visualization

### 2. Performance Analysis
- Real-time angle calculations
- Visual feedback indicators
- Segment markers for key poses
- Progress metrics display

### 3. Data Storage
- Local caching of videos
- Secure cloud storage
- Offline support
- Data synchronization



