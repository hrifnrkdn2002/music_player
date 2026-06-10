import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:music_player/interface.dart';
import 'package:path/path.dart' as p;
import '../model/song.dart';
import '../repository/database_repository.dart';

class DatabaseService extends DatabaseServiceInterface{
  final DatabaseRepositoryInterface _databaseRepositoryInterface;
  DatabaseService(this._databaseRepositoryInterface);

  // 곡 라이브러리 SSOT (싱글톤으로 등록되어 앱 전역이 같은 인스턴스를 공유)
  List<Song> _songs = [];
  final _songsCtrl = StreamController<List<Song>>.broadcast();

  @override
  List<Song> get songs => List.unmodifiable(_songs);

  @override
  Stream<List<Song>> get songsStream => _songsCtrl.stream;

  @override
  Future<void> refreshSongs() async {
    _songs = await _databaseRepositoryInterface.getAllSongs();
    _songsCtrl.add(_songs);
  }

  @override
  Future<void> updateSong(Song song) async {
    await _databaseRepositoryInterface.updateSong(song);
    await refreshSongs();
  }

  @override
  Future<void> deleteSong(int id) async {
    await _databaseRepositoryInterface.deleteSong(id);
    await refreshSongs();
  }


  @override
  Future<bool> pickAndInsertSongs(List<Song> songs) async {
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
    if (result == null || result.files.isEmpty) return false;

    //FilePickerResult? 가 null이 아니므로 반복문을 통해 path를 추출하고 null 검사 후
    //null이면 다음 파일로 넘어가고 null 아니면 중복체크를 통해 중복이면 넘어가고 중복이 아니면
    //Song모델 인스턴스를 만들어서 데이터베이스에 저장
    //반복문이 끝나면 loadSongs()를 호출해 화면과 음악리스트를 업데이트
    for (final file in result.files) {
      final filePath = file.path;
      if (filePath == null) continue;

      // 🔥 중복 체크
      final uniqueKey = '${file.name}_${file.size}';
      if (isDuplicate(songs, uniqueKey)) continue;

      final song = Song(
        title: p.basenameWithoutExtension(file.name),
        artist: null,
        filePath: filePath,
        duration: null,
        albumImagePath: null,
        uniqueKey: uniqueKey,
      );

      await _databaseRepositoryInterface.insertSong(song);
    }
    await refreshSongs();
    return true;
  }
  bool isDuplicate(List<Song> songs, String uniqueKey){
    return songs.any((s)=> s.uniqueKey == uniqueKey );
  }
}