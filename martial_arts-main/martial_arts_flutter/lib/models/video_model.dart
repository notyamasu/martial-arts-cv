class VideoModel {
  final String title;
  final String url;

  VideoModel({required this.title, required this.url});

  @override
  String toString() => title;

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      title: json['title'],
      url: json['url'],
    );
  }
} 