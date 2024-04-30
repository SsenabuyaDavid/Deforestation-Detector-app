import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:tflite_audio/tflite_audio.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audio Analysis'),
      ),
      body: Center(
        child: AudioAnalysisPage(),
      ),
    );
  }
}

class AudioAnalysisPage extends StatefulWidget {
  final List<FileSystemEntity>? audioFiles; // Add a list of audio files

  const AudioAnalysisPage({Key? key, this.audioFiles}) : super(key: key);

  @override
  _AudioAnalysisPageState createState() => _AudioAnalysisPageState();
}

class _AudioAnalysisPageState extends State<AudioAnalysisPage> {
  late Stream<dynamic> recognitionStream;
  String audioResult = 'Waiting for audio analysis...';
  bool isRecognitionComplete = false;
  FileSystemEntity? selectedAudioFile; // Make it nullable

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Analysis'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _selectAudioFile,
              child: const Text('Select Audio File'),
            ),
            const SizedBox(height: 20),
            if (selectedAudioFile != null) ...[
              Text(
                'Selected File: ${selectedAudioFile!.path.split('/').last}',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _startAudioRecognition,
                child: const Text('Start Audio Analysis'),
              ),
              const SizedBox(height: 20),
              isRecognitionComplete
                  ? Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Audio analysis completed!',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : Container(), // Container to show completion status
              const SizedBox(height: 20),
              Text(
                audioResult,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectAudioFile() async {
    final Directory downloadDir = Directory('/storage/emulated/0/Download');
    final List<FileSystemEntity> files = downloadDir.listSync();
    final List<FileSystemEntity> audioFiles = files
        .where((file) =>
            file.path.toLowerCase().endsWith('.wav') ||
            file.path.toLowerCase().endsWith('.mav'))
        .toList();
    setState(() {
      selectedAudioFile = audioFiles.isNotEmpty ? audioFiles.first : null;
      audioResult = 'Waiting for audio analysis...';
      isRecognitionComplete = false;
    });
  }

  void _startAudioRecognition() {
    if (selectedAudioFile == null) return;

    recognitionStream = TfliteAudio.startFileRecognition(
      sampleRate: 16000,
      audioDirectory: selectedAudioFile!.path,
    );

    recognitionStream.listen((event) {
      final result = event['recognitionResult'];
      if (result == 'chainsaw_detected') {
        sendChainsawDetectionEmail();
      }
      setState(() {
        audioResult = result;
      });
    }).onDone(() {
      setState(() {
        isRecognitionComplete = true;
      });
      TfliteAudio.stopAudioRecognition();
    });
  }

  void sendChainsawDetectionEmail() async {
    String username = 'defordetector@gmail.com';
    String password = 'defordetector@2024';

    final smtpServer = gmail(username, password);

    final emailMessage = Message()
      ..from = Address(username, 'Your name')
      ..recipients.add('daveseynabou@gmail.com')
      ..subject = 'Chainsaw Sound Detected'
      ..text = 'A chainsaw sound was detected. Please take necessary action.';

    try {
      await send(emailMessage, smtpServer);
      print('Email sent successfully!');
    } on MailerException catch (e) {
      print('Error sending email: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
    }
  }
}
