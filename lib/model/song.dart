class Song {
  final int? id;
  final String title;
  final String? artist;
  final String filePath;
  final int? duration;
  final String? uniqueKey;
  final String? albumImagePath; // ✅ 추가
  final bool isYoutube; // 유튜브 스트리밍 곡 여부 (true면 filePath에 video URL 저장)

  Song({
    this.id,
    required this.title,
    this.artist,
    required this.filePath,
    this.duration,
    this.uniqueKey,
    this.albumImagePath, // ✅ 추가
    this.isYoutube = false,
  });
  //직렬화
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'file_path': filePath,
      'duration': duration,
      'unique_key': uniqueKey,
      'album_image_path': albumImagePath, // ✅ 추가
      'is_youtube': isYoutube ? 1 : 0,
    };
  }
  //역직렬화
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'],
      title: map['title'],
      artist: map['artist'],
      filePath: map['file_path'],
      uniqueKey: map['unique_key'],
      duration: map['duration'],
      albumImagePath: map['album_image_path'], // ✅ 추가
      isYoutube: (map['is_youtube'] ?? 0) == 1,
    );
  }
}
