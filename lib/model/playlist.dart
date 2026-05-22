class Playlist {
  final int id;
  final String name;
  final int updatedAt;
  final int count;

  Playlist({
    required this.id,
    required this.name,
    required this.updatedAt,
    required this.count
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'updated_at': updatedAt,
      'count': count
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'],
      name: map['name'],
      updatedAt: map['updated_at'],
      count: map['count']
    );
  }

}