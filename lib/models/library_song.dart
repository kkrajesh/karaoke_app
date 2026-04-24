class LibrarySong {
  final String id;
  final String title;
  final String artist;
  final String videoId;
  final int rating;
  final String source; // 'youtube', 'local', 'smule'
  final bool hasPreview;

  LibrarySong({
    required this.id,
    required this.title,
    required this.artist,
    required this.videoId,
    this.rating = 0,
    this.source = 'youtube',
    this.hasPreview = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'videoId': videoId,
      'rating': rating,
      'source': source,
      'hasPreview': hasPreview,
    };
  }

  factory LibrarySong.fromMap(Map<String, dynamic> map) {
    return LibrarySong(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      videoId: map['videoId'] ?? '',
      rating: map['rating'] ?? 0,
      source: map['source'] ?? 'youtube',
      hasPreview: map['hasPreview'] ?? false,
    );
  }
}
