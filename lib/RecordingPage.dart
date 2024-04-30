import 'dart:async';
import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fft/flutter_fft.dart';
import 'package:record/record.dart'; //for recording

class RecordingPage extends StatefulWidget {
  const RecordingPage({Key? key}) : super(key: key);

  @override
  _RecordingPageState createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  late Record _audioRecorder;
  StreamSubscription<Amplitude>? _amplitudeSub;
  bool _isRecording = false;
  List<FileSystemEntity> _recordedAudios = [];
  String _text = '---';
  late FlutterFft _flutterFft;
  late AssetsAudioPlayer _assetsAudioPlayer;

  @override
  void initState() {
    super.initState();
    _audioRecorder = Record();
    _flutterFft = FlutterFft();
    _assetsAudioPlayer = AssetsAudioPlayer();
    _initialize();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _amplitudeSub?.cancel();
    _flutterFft.stopRecorder();
    _assetsAudioPlayer.dispose(); // Dispose the AssetsAudioPlayer
    super.dispose();
  }

  Future<void> _initialize() async {
    final permissionStatus = await Record().hasPermission();
    if (permissionStatus) {
      _amplitudeSub = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amp) {
        setState(() {
          _text = 'Amplitude: ${amp.current}';
        });
      });
    } else {
      print('Permission denied');
    }
  }

  Future<void> _startRecording() async {
    final permissionStatus = await _audioRecorder.hasPermission();
    if (permissionStatus) {
      setState(() {
        _isRecording = true;
      });
      await _audioRecorder.start(
        path:
            'storage/emulated/0/Download/recording${_recordedAudios.length + 1}.wav',
        encoder: AudioEncoder.wav,
      );
      _flutterFft.startRecorder();
    } else {
      print('Permission denied');
    }
  }

  Future<void> _stopRecording() async {
    await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _recordedAudios.add(File(
          'storage/emulated/0/Download/recording${_recordedAudios.length + 1}.wav'));
    });
    _flutterFft.stopRecorder();
  }

  Future<void> _playAudio(String filePath) async {
    try {
      await _assetsAudioPlayer
          .open(Audio.file(filePath)); // Open the audio file
      _assetsAudioPlayer.play(); // Play the audio
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording Page'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(_text),
          ElevatedButton(
            onPressed: _isRecording ? null : _startRecording,
            child: const Text('Start Recording'),
          ),
          ElevatedButton(
            onPressed: _isRecording ? _stopRecording : null,
            child: const Text('Stop Recording'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _recordedAudios.length,
              itemBuilder: (context, index) {
                final audioPath = _recordedAudios[index].path;
                return ListTile(
                  title: Text('Recording ${index + 1}'),
                  onTap: () {
                    _playAudio(audioPath); // Play the audio when tapped
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
