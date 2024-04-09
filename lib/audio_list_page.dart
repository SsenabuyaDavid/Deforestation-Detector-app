import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioListPage extends StatelessWidget {
  final List<FileSystemEntity> songs;

  const AudioListPage({Key? key, required this.songs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio List'),
      ),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          String fileName = songs[index].uri.pathSegments.last;
          return ListTile(
            title: Text(fileName),
            onTap: () {
              playAudio(songs[index].path);
            },
          );
        },
      ),
    );
  }

  Future<void> playAudio(String audioPath) async {
    AudioPlayer audioPlayer =
        AudioPlayer(); // Create an instance of AudioPlayer

    int result =
        await audioPlayer.play(audioPath, isLocal: true); // Play the audio

    if (result == 1) {
      // Success
      print('Audio playing successfully');
    } else {
      // Error
      print('Error playing audio');
    }
  }
}
