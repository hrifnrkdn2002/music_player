import 'package:flutter/cupertino.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';

class YoutubeStreamAudioSource extends StreamAudioSource {
  final YoutubeExplode yt;
  final AudioStreamInfo streamInfo;

  YoutubeStreamAudioSource(this.yt, this.streamInfo);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= streamInfo.size.totalBytes;

    // 공개 API인 streams.get()은 항상 0번 바이트부터 스트림을 주므로,
    // start가 0보다 크면(탐색 등) 앞부분 바이트를 건너뛴다.
    var stream = yt.videos.streams.get(streamInfo);
    if (start > 0) {
      stream = _skipBytes(stream, start);
    }

    return StreamAudioResponse(
      sourceLength: streamInfo.size.totalBytes,
      contentLength: end - start,
      offset: start,
      stream: stream,
      contentType: streamInfo.codec.mimeType,
    );
  }

  Stream<List<int>> _skipBytes(Stream<List<int>> source, int count) async* {
    var skipped = 0;
    await for (final chunk in source) {
      if (skipped >= count) {
        yield chunk;
      } else if (skipped + chunk.length <= count) {
        skipped += chunk.length;
      } else {
        yield chunk.sublist(count - skipped);
        skipped = count;
      }
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const url = 'https://www.youtube.com/watch?v=V_QC5RonHLk';

  var yt = YoutubeExplode();
  var video = await yt.videos.get(url);

  print(video.title);
  print(video.author);
  print(video.duration);

  // 기본 클라이언트(androidSdkless)는 ratebypass 없는 throttle URL을 줘서
  // 스트리밍 중 SocketTimeout이 난다. androidVr/ios는 non-throttled URL을 준다.
  var streamManifest = await yt.videos.streams.getManifest(
    url,
    ytClients: [YoutubeApiClient.androidVr, YoutubeApiClient.ios],
  );//라이브러리가 클라이언트인 척 위조해서 무사히 cdn주소를 받아냄
  var streamInfo = streamManifest.audioOnly.withHighestBitrate();

  print('tag: ${streamInfo.tag}, throttled: ${streamInfo.isThrottled}');

  final player = AudioPlayer();
  await player.setAudioSource(YoutubeStreamAudioSource(yt, streamInfo));
  await player.play();

  await Future.delayed(Duration(minutes: 5));
}