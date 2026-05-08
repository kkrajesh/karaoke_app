class Song {
  final String id;
  final String title;
  final String videoId; // Used as video ID for YT, or file path/name for local
  final bool isLocal;
  final String requestedBy;
  final String requestedByName;
  final String? duetSingerName;
  final DateTime addedAt;
  
  String get displaySingerName {
    if (duetSingerName != null && duetSingerName!.isNotEmpty) {
      return '$requestedByName & $duetSingerName';
    }
    return requestedByName;
  }
  
  // Audience Request Fields
  final bool isRequest;
  final String? requestedFor;
  final String? dedication;
  final String? hostNote;

  Song({
    required this.id,
    required this.title,
    required this.videoId,
    this.isLocal = false,
    required this.requestedBy,
    required this.requestedByName,
    this.duetSingerName,
    required this.addedAt,
    this.isRequest = false,
    this.requestedFor,
    this.dedication,
    this.hostNote,
  });

  factory Song.fromMap(Map<String, dynamic> map, String documentId) {
    return Song(
      id: documentId,
      title: map['title'] ?? '',
      videoId: map['videoId'] ?? '',
      isLocal: map['isLocal'] ?? false,
      requestedBy: map['requestedBy'] ?? '',
      requestedByName: map['requestedByName'] ?? '',
      duetSingerName: map['duetSingerName'],
      addedAt: map['addedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['addedAt']) 
          : DateTime.now(),
      isRequest: map['isRequest'] ?? false,
      requestedFor: map['requestedFor'],
      dedication: map['dedication'],
      hostNote: map['hostNote'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'videoId': videoId,
      'isLocal': isLocal,
      'requestedBy': requestedBy,
      'requestedByName': requestedByName,
      if (duetSingerName != null) 'duetSingerName': duetSingerName,
      'addedAt': addedAt.millisecondsSinceEpoch,
      'isRequest': isRequest,
      if (requestedFor != null) 'requestedFor': requestedFor,
      if (dedication != null) 'dedication': dedication,
      if (hostNote != null) 'hostNote': hostNote,
    };
  }

  Song copyWith({
    String? id,
    String? title,
    String? videoId,
    bool? isLocal,
    String? requestedBy,
    String? requestedByName,
    String? duetSingerName,
    DateTime? addedAt,
    bool? isRequest,
    String? requestedFor,
    String? dedication,
    String? hostNote,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      videoId: videoId ?? this.videoId,
      isLocal: isLocal ?? this.isLocal,
      requestedBy: requestedBy ?? this.requestedBy,
      requestedByName: requestedByName ?? this.requestedByName,
      duetSingerName: duetSingerName ?? this.duetSingerName,
      addedAt: addedAt ?? this.addedAt,
      isRequest: isRequest ?? this.isRequest,
      requestedFor: requestedFor ?? this.requestedFor,
      dedication: dedication ?? this.dedication,
      hostNote: hostNote ?? this.hostNote,
    );
  }
}
