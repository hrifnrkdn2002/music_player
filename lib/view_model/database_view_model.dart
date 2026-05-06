import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:music_player/model/song.dart';
import 'package:music_player/repository/database_repository.dart';
import 'package:path/path.dart' as p;

class DatabaseViewModel extends ChangeNotifier {
  //final로 선언된 리스트는 내부 값 변경 가능, 메모리 주소만 안바뀜
  //반면 int 같은 기본형은 내부 값도 불변
  final List<Song> _songs = [];
  // dart에서는 _을 안붙이면 default가 public 붙이면 private임, protect/protected/internal 같은 거 없음
  bool _isLoading = false;

  //_songs의 getter 메소드
  //리스트의 내용만 복사해서 보내줌, 그냥 _songs를 보내면 메모리주소를 참조해버려서 외부에서 _songs 수정이 가능해짐
  //List.unmodifable은 원본과 다른 메모리 주소에 List를 복사하며 절대 리스트를 수정할 수 없게 함
  List<Song> get songs => List.unmodifiable(_songs);
  // _isLoading의 getter 메소드
  bool get isLoading => _isLoading;

  //플레이리스트 목록을 담아둘 리스트 ,플레이리스트의 곡정보는 없고 플레이리스트 자체 정보만 가지고있음
  List<Map<String, dynamic>> _playlists = [];
  // _playlists의 getter 메소드
  List<Map<String, dynamic>> get playlists => List.unmodifiable(_playlists);

  /* =======================================================================
   * 기존 곡 관련 메서드들
   * ======================================================================= */
  //TODO: loadSongs의 Usages를 찾아서 리팩토링
  Future<void> loadSongs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loadedSongs = await DatabaseRepository.instance.getAllSongs();

      //Provider로 주입된 viewmodel이기 때문에 인스턴스가 앱전반에 걸쳐 공유됨
      //따라서 기존 _songs 리스트를 클리어하고 새로운 데이터로 갈아끼워야함
      //.은 반환값을 가져오지만 ..으로 실행한 메서드는 자기가 무엇을 반환하든 무시하고 자신을 실행시킨 원본객체를 반환함
      //cascade 메서드 사용법임
      _songs
        ..clear()
        ..addAll(loadedSongs);
    } catch (e) {
      debugPrint('loadSongs 오류: $e');
    } finally {
      // isLoading은 default가 false이어야 하므로 finally를 통해서 보장
      _isLoading = false;
      notifyListeners();
    }
  }
  //핸드폰 파일시스템에서 음악을 선택하고 데이터베이스에 저장하는 메서드
  Future<void> pickAndInsertSongs() async {
    try {
      //pickFiles() 메서드는 반환값이 FilePickerResult? 이다
      //FilePickerResult 클래스 내부는 List<PlatformFile> files,
      //List<String> names, List<String> paths로 구성되어있다
      //PlatformFile 객체는 path,name,size로 구성되어있다.
      //따라서 result의 타입은 FilePickerResult? 이다.
      final result = await FilePicker.platform.pickFiles(
        //TODO: 현재 파일시스템에 접근 시 오디오파일 외에 다른 파일도 모두 보임 처음부터 오디오 파일만 보이게 고칠 것
        type: FileType.audio,
        //TODO: 현재 다중선택을 하려면 첫선택을 꾹 눌러야함 살짝만 터치해도 file_picker가 꺼지지 않고 계속 선택할 수 있게 고칠 것
        allowMultiple: true,
      );

      //FilePicker는 파일선택을하지 않을 시 FilePickerResult에 null을 반환함.
      //선택을 안하면 return을 통해 더이상의 동작없이 함수 밖으로 나오게 함.
      if (result == null || result.files.isEmpty) return;

      //FilePickerResult? 가 null이 아니므로 반복문을 통해 path를 추출하고 null 검사 후
      //null이면 다음 파일로 넘어가고 null 아니면 중복체크를 통해 중복이면 넘어가고 중복이 아니면
      //Song모델 인스턴스를 만들어서 데이터베이스에 저장
      //반복문이 끝나면 loadSongs()를 호출해 화면과 음악리스트를 업데이트
      for (final file in result.files) {
        final filePath = file.path;
        if (filePath == null) continue;

        // 🔥 중복 체크
        final uniqueKey = '${file.name}_${file.size}';

        final exists = _songs.any((song) => song.uniqueKey == uniqueKey);
        if (exists) continue;

        final song = Song(
          title: p.basenameWithoutExtension(file.name),
          artist: null,
          filePath: filePath,
          duration: null,
          albumImagePath: null,
          uniqueKey: uniqueKey,
        );

        await DatabaseRepository.instance.insertSong(song);
      }

      await loadSongs();
    } catch (e) {
      debugPrint('오류: $e');
    }
  }

  Future<void> insertSong(Song song) async {
    try {
      await DatabaseRepository.instance.insertSong(song);
      //TODO: pickAndInsertSongs에서 loadSongs를 호출했는데도 여기서 또 호출 함 중복호출인지 확인 해볼 것
      await loadSongs();
    } catch (e) {
      debugPrint('insertSong 오류: $e');
    }
  }

  Future<void> deleteSong(int id) async {
    try {
      await DatabaseRepository.instance.deleteSong(id);
      // TODO: 데이터베이스에서 삭제하고 loadSongs()를 호출해야할 것 같은데 하지 않음 확인해 볼 것
      // 만약 호출한다면 리스트를 따로 조작할 필요는 없을 것 같음
      _songs.removeWhere((song) => song.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('deleteSong 오류: $e');
    }
  }

  Future<void> updateSong(Song song) async {
    try {
      //데이터베이스 업데이트후 loadSongs() 호출로 songs리스트 갱신
      await DatabaseRepository.instance.updateSong(song);
      await loadSongs();
    } catch (e) {
      debugPrint('updateSong 오류: $e');
    }
  }

  /* =======================================================================
   *플레이리스트 관련 메서드 (신규 추가)
   * ======================================================================= */

  // 💡 1. 플레이리스트 목록 조회 (최신 업데이트순 정렬)
  Future<void> loadPlaylists() async {
    try {
      final loadedPlaylists = await DatabaseRepository.instance.getPlaylists();
      //List.from은 원본과 다른 메모리 주소에 리스트를 복사함 수정 가능
      //단 이 파일에서는 getter에서 List.unmodifable로 한 번 더 감싸기 때문에 이 파일 내부에서만 수정가능
      _playlists = List.from(loadedPlaylists);
      notifyListeners(); // UI에 데이터가 변경되었음을 알림
    } catch (e) {
      debugPrint('loadPlaylists 오류: $e');
    }
  }

  // 💡 2. 플레이리스트 생성
  Future<void> createPlaylist(String name) async {
    try {
      await DatabaseRepository.instance.createPlaylist(name);
      await loadPlaylists(); // 생성 후 목록을 새로고침하여 최신순 정렬 반영
    } catch (e) {
      debugPrint('createPlaylist 오류: $e');
    }
  }

  // 💡 3. 플레이리스트 이름 수정
  Future<void> updatePlaylistName(int id, String newName) async {
    try {
      await DatabaseRepository.instance.updatePlaylistName(id, newName);
      await loadPlaylists(); // 수정 후 목록을 새로고침하여 최신순 정렬 반영
    } catch (e) {
      debugPrint('updatePlaylistName 오류: $e');
    }
  }

  // 💡 4. 플레이리스트 삭제
  //재생하고 있는 플레이리스트를 삭제 시 어떻게 동작하고 있는 지 확인 할 것
  Future<void> deletePlaylist(int id) async {
    try {
      await DatabaseRepository.instance.deletePlaylist(id);
      await loadPlaylists(); // 삭제 후 목록 갱신
    } catch (e) {
      debugPrint('deletePlaylist 오류: $e');
    }
  }

  /* =======================================================================
   * 플레이리스트 상세 관련 메서드
   * ======================================================================= */

  // 1. 플레이리스트에 곡 추가
  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    try {
      await DatabaseRepository.instance.addSongToPlaylist(playlistId, songId);
      notifyListeners();
    } catch (e) {
      debugPrint('addSongToPlaylist 오류: $e');
    }
  }

  // 2. 플레이리스트 곡 조회
  Future<List<Song>> getSongsInPlaylist(int playlistId) async {
    try {
      return await DatabaseRepository.instance.getSongsInPlaylist(playlistId);
    } catch (e) {
      debugPrint('getSongsInPlaylist 오류: $e');
      return [];
    }
  }

  // 3. 플레이리스트에서 곡 삭제
  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    try {
      await DatabaseRepository.instance.removeSongFromPlaylist(
        playlistId,
        songId,
      );
      //TODO:getSongsInPlaylist을 호출하지 않았는데 view에서 song리스트를 업데이트 하는 지 확인해볼 것
      notifyListeners();
    } catch (e) {
      debugPrint('removeSongFromPlaylist 오류: $e');
    }
  }

  //순서저장메서드
  //TODO: songs를 넘겨주기전에 이미 view에서 songs를 업데이트 함. 해당 로직을 적절한 곳으로 옮길 것
  Future<void> updatePlaylistSongOrder(int playlistId, List<Song> songs) async {
    try {
      await DatabaseRepository.instance.updatePlaylistSongOrder(
        playlistId,
        songs,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('updatePlaylistSongOrder 오류: $e');
    }
  }
}
