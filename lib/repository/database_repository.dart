import 'package:music_player/index/repository_index.dart';
import 'package:music_player/interface.dart';
import 'package:music_player/model/playlist.dart';

//이 클래스는 데이터베이스레포지터리인터페이스의 구현클래스
class DatabaseRepository extends DatabaseRepositoryInterface{

  final Database _database;

  DatabaseRepository(this._database);


  /* ==================== [기존 곡 관련 메서드] ==================== */

  //데이터베이스레포지터리인터페이스 메서드의 구현부
  //Song 모델객체를 받아서 직렬화 후 songs 테이블에 삽입
  //만약 충돌이 일어나면 삽입무시후 -1 반환
  /*
    conflictAlgorithm의 속성으로는
    ignore  충돌 시 삽입 무시, 기존 데이터 유지
    replace 충돌 시 기존 행 삭제 후 새 행 삽입
    abort   충돌 시 트랜잭션 롤백 (기본값)
    fail    충돌 시 에러 반환
    rollback충돌 시 전체 트랜잭션 롤백

    rollback이 의미 있으려면 여러 트랜잭션 처리를 블록화해야함
    따로따로 하면 abort와 다른게 없음 insertSong 구현부가 아니라 호출부에서 트랜잭션처리를해야함

    반환값은 삽인된 행의 rowId (설정한 primary key가 있다면 자동으로 rowId가 됨) )
  */
  @override
  Future<int> insertSong(Song song) async {

    return await _database.insert(
      'songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /*
  * 모든 곡의 데이터를 모델 형태로 리스트에 담아 가져오는 메서드
  * id DESC는 id 내림차순으로 정렬이다. 이유는 최신순으로 리스트에 담기 위해서
  * result.map()은 Iterable 변수를 순회하며 변환하기 위해 사용
  * .map()은 지연실행이므로 실제 순회가 일어날때 변환 함. 반환 타입은 Iterable
  * 단순출력이면 상관없으나 실제 List나 Set, 인덱스 접근이 필요하다면 toList, toSet 등으로 변환할 것
  * 데이터베이스의 query 메서드가 조회기능을 담당
  */
  @override
  Future<List<Song>> getAllSongs() async {
    final result = await _database.query('songs', orderBy: 'id DESC');
    return result.map((map) => Song.fromMap(map)).toList();
  }
  //반환 값은 삭제된 행의 수
  @override
  Future<int> deleteSong(int id) async {
    return await _database.delete('songs', where: 'id = ?', whereArgs: [id]);
  }
  //반환 값은 업데이트된 행의 수
  @override
  Future<int> updateSong(Song song) async {
    return await _database.update(
      'songs',
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }

  /* ==================== [ 플레이리스트 관련 메서드] ==================== */

  // 플레이리스트 생성 (항상 현재 시간을 밀리초로 저장하여 최신순 정렬에 활용)
  // 반환값은 삽입된 행의 rowId
  @override
  Future<int> createPlaylist(String name) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    //중복된 이름이어도 생성가능한 지 확인할 것 => 현재 중복이 가능하다, 이대로 유지할 것임
    return await _database.insert('playlists', {'name': name, 'updated_at': now});
  }

  // 플레이리스트 목록 조회 (곡 수 포함, 최신 업데이트순 정렬)
  // 플레이리스트는 모든 칼럼과 로우 조회, group by로 별도의 임시 테이블을 만듬 플레이리스트 id로 그룹화해서,
  // left join으로 플레이리스트는 모두 남기고 플레이리스트의 id를 가진 관계형테이블의 칼럼과 로우만 남김
  // 그룹화된 테이블에서 count값만 뽑아옴, ORDER BY로 최신순 정렬
  // query()는 파라미터로 조건 전달 단순조회에 적합
  // rawQuery()는 sql문 직접 작성 복잡한 조회에 적합
  @override
  Future<List<Playlist>> getPlaylists() async {
    final result =  await _database.rawQuery('''
      SELECT p.*, COUNT(ps.song_id) as count  
      FROM playlists p
      LEFT JOIN playlist_songs ps ON p.id = ps.playlist_id
      GROUP BY p.id
      ORDER BY p.updated_at DESC
    ''');
    return result.map((map) => Playlist.fromMap(map)).toList();
  }

  // 플레이리스트 이름 수정 (수정 시에도 최신순으로 맨 위로 올려야 하므로 updated_at을 갱신합니다)
  // millisecondsSinceEpoch는 현재 시간을 밀리초로, 정수형으로 반환하는 메서드
  // SQLite는 DateTime 타입이 따로없어서 정수형 또는 문자열로 저장해야함
  @override
  Future<int> updatePlaylistName(int id, String newName) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return await _database.update(
      'playlists',
      {'name': newName, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 플레이리스트 삭제
  @override
  Future<int> deletePlaylist(int id) async {
    return await _database.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  /* ==================== [🔥 추가: 플레이리스트 상세 관련 메서드] ==================== */

  // 1. 플레이리스트에 곡 추가 (중복 방지 포함)
  // 이미 플레이리스트에 있는 곡이면 0을 반환하고, max_order가 null 이면 -1을 반환, 무사히 삽입 하면 1을 반환
  @override
  Future<int> addSongToPlaylist(int playlistId, int songId) async {
    final existing = await _database.query(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
    if (existing.isNotEmpty) return 0;

    final result = await _database.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) as max_order FROM playlist_songs WHERE playlist_id = ?',
      [playlistId],
    );

    final maxOrder = (result.first['max_order'] as int?) ?? -1;

    return await _database.insert('playlist_songs', {
      'playlist_id': playlistId,
      'song_id': songId,
      'sort_order': maxOrder + 1,
    });
  }

  // 2. 플레이리스트에 담긴 곡 목록 조회 (JOIN 활용)
  @override
  Future<List<Song>> getSongsInPlaylist(int playlistId) async {
    final result = await _database.rawQuery(
      '''
    SELECT s.* FROM songs s
    INNER JOIN playlist_songs ps ON s.id = ps.song_id
    WHERE ps.playlist_id = ?
    ORDER BY ps.sort_order ASC
  ''',
      [playlistId],
    );

    return result.map((map) => Song.fromMap(map)).toList();
  }

  // 3. 플레이리스트에서 특정 곡 제외 (원본 파일은 유지)
  @override
  Future<int> removeSongFromPlaylist(int playlistId, int songId) async {
    return await _database.delete(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
  }

  //순서저장메서드추가
  //플레이리스트 id와 새로운 Song 리스트를 받음
  //for문으로 새로 받은 리스트의 첫번째 인덱스부터 마지막 인덱스까지 요소의 id를 받아서 순서대로 sort_order 값을 업데이트
  //batch.commit()을 호출할때 한번에 순차적으로 실행됨. transaction과 다른 점: 실패해도 계속 진행, 원자성보단 성능최적화를 위함, 각 작업결과를 List로 반환
  @override
  Future<void> updatePlaylistSongOrder(int playlistId, List<Song> songs) async {
    final batch = _database.batch();

    for (int i = 0; i < songs.length; i++) {
      final songId = songs[i].id;
      if (songId == null) continue;

      batch.update(
        'playlist_songs',
        {'sort_order': i},
        where: 'playlist_id = ? AND song_id = ?',
        whereArgs: [playlistId, songId],
      );
    }

    await batch.commit(noResult: true); //작업결과 반환 안받음
  }
}
