import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player/DB/DB_Provider.dart';

class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: ElevatedButton(
            onPressed: ()=>DB_Provider().pickAndInsertSongs(),
            child: Text('다운로드'))
    );
  }
}