import 'dart:io';

import 'package:flutter/material.dart';

import 'LocationPage.dart';
import 'RecordingPage.dart';
import 'audio_analysis_page.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Deforestation Detector',
      debugShowCheckedModeBanner: false,
      home: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // Declare and initialize the audioFiles list here
  final List<String> audioFilePaths = [
    'audio_file_1.mp3',
    'audio_file_2.mp3',
    // Add more audio file paths as needed
  ];

  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert the list of file paths to a list of FileSystemEntity
    final List<FileSystemEntity> audioFiles = audioFilePaths
        .map((path) => File(path))
        .toList(); // Convert each file path to a File object

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecordingPage(),
                  ),
                );
              },
              child: const Text('Record Audio from microphone'),
            ),
            ElevatedButton(
              onPressed: () {
                if (audioFiles.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AudioAnalysisPage(
                        audioFiles: audioFiles,
                      ),
                    ),
                  );
                } else {
                  // Show a message indicating no audio files are available
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('No Audio Files'),
                      content: const Text(
                          'There are no audio files available for analysis.'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Text('Analyze Audio'),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationPage(),
                  ),
                );
              },
              child: const Text('Get Device Location'),
            ),
          ],
        ),
      ),
    );
  }
}
