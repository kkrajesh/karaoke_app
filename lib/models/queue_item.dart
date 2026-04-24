class QueueItem {
  final String name;
  final String song;
  final String type; // 'youtube' or 'local'
  final String source;

  QueueItem({
    required this.name,
    required this.song,
    required this.type,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'song': song,
        'type': type,
        'source': source,
      };

  factory QueueItem.fromJson(Map<String, dynamic> json) => QueueItem(
        name: json['name'],
        song: json['song'],
        type: json['type'],
        source: json['source'],
      );
}
