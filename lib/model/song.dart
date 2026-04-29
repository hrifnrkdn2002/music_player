class Song {
  final int? id;
  final String title;
  final String? artist;
  final String filePath;
  final int? duration;
  final String? uniqueKey;
  final String? albumImagePath; // ✅ 추가

  Song({
    this.id,
    required this.title,
    this.artist,
    required this.filePath,
    this.duration,
    this.uniqueKey,
    this.albumImagePath, // ✅ 추가
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'file_path': filePath,
      'duration': duration,
      'unique_key': uniqueKey,
      'album_image_path': albumImagePath, // ✅ 추가
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'],
      title: map['title'],
      artist: map['artist'],
      filePath: map['file_path'],
      uniqueKey: map['unique_key'],
      duration: map['duration'],
      albumImagePath: map['album_image_path'], // ✅ 추가
    );
  }
}
