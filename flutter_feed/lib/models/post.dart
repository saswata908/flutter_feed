class Post {
  final String id;
  final String mediaThumbUrl;
  final String mediaMobileUrl;
  final String mediaRawUrl;
  final int likeCount;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.mediaThumbUrl,
    required this.mediaMobileUrl,
    required this.mediaRawUrl,
    required this.likeCount,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      mediaThumbUrl: json['media_thumb_url'],
      mediaMobileUrl: json['media_mobile_url'],
      mediaRawUrl: json['media_raw_url'],
      likeCount: json['like_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
