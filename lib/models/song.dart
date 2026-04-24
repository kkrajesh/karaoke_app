class Song {
  final String id;
  final String title;
  final String videoId; // Used as video ID for YT, or file path/name for local
  final bool isLocal;
  final String requestedBy;
  final String requestedByName;
  final DateTime addedAt;

  Song({
    required this.id,
    required this.title,
    required this.videoId,
    this.isLocal = false,
    required this.requestedBy,
    required this.requestedByName,
    required this.addedAt,
  });

  factory Song.fromMap(Map<String, dynamic> map, String documentId) {
    return Song(
      id: documentId,
      title: map['title'] ?? '',
      videoId: map['videoId'] ?? '',
      isLocal: map['isLocal'] ?? false,
      requestedBy: map['requestedBy'] ?? '',
      requestedByName: map['requestedByName'] ?? '',
      addedAt: map['addedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['addedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'videoId': videoId,
      'isLocal': isLocal,
      'requestedBy': requestedBy,
      'requestedByName': requestedByName,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }
}
