import 'dart:async';
import 'dart:io';

// import 'dart:nativewrappers/_internal/vm/lib/core_patch.dart';

import 'package:audio_fingerprint/RecordingPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:onnxruntime/onnxruntime.dart';

import 'Functions.dart';

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
        child: RecordingPage(),
      ),
    );
  }
}

class AudioAnalysisPage extends StatefulWidget {
  final List<FileSystemEntity>? audioFiles;

  const AudioAnalysisPage({Key? key, this.audioFiles}) : super(key: key);

  @override
  _AudioAnalysisPageState createState() => _AudioAnalysisPageState();
}

class _AudioAnalysisPageState extends State<AudioAnalysisPage> {
  late Stream<dynamic> recognitionStream;
  String audioResult = 'Waiting for audio analysis...';
  bool isRecognitionComplete = false;
  FileSystemEntity? selectedAudioFile;
  // OrtSession? _ortSession;

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
              onPressed: () async {
                await _selectAudioFile();
              },
              // _selectAudioFile,
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
              if (!isRecognitionComplete) ...[
                CircularProgressIndicator(),
              ] else ...[
                Text(
                  'Audio Analysis Result: $audioResult',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // Future<List<FileSystemEntity>> _selectAudioFile() async {
  //   String audioFilePath = 'storage/emulated/0/Download/';
  //   final List<FileSystemEntity> files = Directory(audioFilePath).listSync();

  //   // Filter audio files
  //   final List<FileSystemEntity> audioFiles = files
  //       .where((file) =>
  //           file.path.toLowerCase().endsWith('.wav') ||
  //           file.path.toLowerCase().endsWith('.mav'))
  //       .toList();

  //   // Check if any audio files exist
  //   if (audioFiles.isNotEmpty) {
  //     // Select the first audio file
  //     setState(() {
  //       selectedAudioFile = audioFiles.first;
  //       audioResult = 'Waiting for audio analysis...';
  //       isRecognitionComplete = false;
  //       print("the audioFile is $audioFiles");
  //     });
  //   } else {
  //     // Handle case where no audio files are found
  //     print('No audio files found in the directory');
  //   }

  //   return audioFiles;
  // }

  // Future<List<FileSystemEntity>> _selectAudioFile() async {
  //   String audioFilePath = 'storage/emulated/0/Download/';
  //   final directory = Directory(audioFilePath);

  //   // Check if directory exists
  //   if (await directory.exists()) {
  //     // Get list of files
  //     final List<FileSystemEntity> files = await directory.list().toList();

  //     // Filter audio files
  //     final List<FileSystemEntity> audioFiles = files
  //         .where((file) =>
  //             file.path.toLowerCase().endsWith('.wav') ||
  //             file.path.toLowerCase().endsWith('.mav'))
  //         .toList();

  //     // Check if any audio files exist
  //     if (audioFiles.isNotEmpty) {
  //       // Display list of audio files
  //       int? selectedIndex = await showDialog<int>(
  //         context: context,
  //         builder: (BuildContext context) {
  //           return AlertDialog(
  //             title: Text('Select Audio File'),
  //             content: Container(
  //               width: double.maxFinite,
  //               height: 300, // Example fixed height
  //               child: ListView.builder(
  //                 shrinkWrap: true,
  //                 itemCount: audioFiles.length,
  //                 itemBuilder: (context, index) {
  //                   return ListTile(
  //                     title: Text(audioFiles[index].path.split('/').last),
  //                     onTap: () => Navigator.pop(context, index),
  //                   );
  //                 },
  //               ),
  //             ),
  //           );
  //         },
  //       );

  //       if (selectedIndex != null) {
  //         setState(() {
  //           selectedAudioFile = audioFiles[selectedIndex];
  //           audioResult = 'Waiting for audio analysis...';
  //           isRecognitionComplete = false;
  //           print("the audioFile is ${selectedAudioFile!.path}");
  //         });
  //       }
  //       return audioFiles;
  //     } else {
  //       // Handle case where no audio files are found
  //       print('No audio files found in the directory');
  //     }

  //   } else {
  //     // Handle case where directory doesn't exist
  //     print('Directory does not exist');
  //   }

  // }

  Future<List<FileSystemEntity>> _selectAudioFile() async {
    String audioFilePath = 'storage/emulated/0/Download/';
    final directory = Directory(audioFilePath);

    // Check if directory exists
    if (await directory.exists()) {
      // Get list of files
      final List<FileSystemEntity> files = await directory.list().toList();

      // Filter audio files
      final List<FileSystemEntity> audioFiles = files
          .where((file) =>
              file.path.toLowerCase().endsWith('.wav') ||
              file.path.toLowerCase().endsWith('.mav'))
          .toList();

      // Check if any audio files exist
      if (audioFiles.isNotEmpty) {
        // Display list of audio files
        int? selectedIndex = await showDialog<int>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Select Audio File'),
              content: Container(
                width: double.maxFinite,
                height: 300, // Example fixed height
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: audioFiles.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(audioFiles[index].path.split('/').last),
                      onTap: () => Navigator.pop(context, index),
                    );
                  },
                ),
              ),
            );
          },
        );

        if (selectedIndex != null) {
          setState(() {
            selectedAudioFile = audioFiles[selectedIndex];
            audioResult = 'Waiting for audio analysis...';
            isRecognitionComplete = false;
            print("the audioFile is ${selectedAudioFile!.path}");
          });
        }

        return audioFiles;
      } else {
        // Handle case where no audio files are found
        print('No audio files found in the directory');
      }
    } else {
      // Handle case where directory doesn't exist
      print('Directory does not exist');
    }

    // Return an empty list if no audio files are found or if the directory doesn't exist
    return [];
  }

  Future<List<OrtValue?>?> performInference() async {
    // Initializing environment

    try {
      // Creating the Session
      final sessionOptions = OrtSessionOptions();
      const assetFileName = 'assets/models/chainsaw_detection.onnx';
      final rawAssetFile = await rootBundle.load(assetFileName);
      final bytes = rawAssetFile.buffer.asUint8List();
      final session = OrtSession.fromBuffer(bytes, sessionOptions!);

      try {
        // Performing inference
        final shape = [4991, 257, 1];
        // final data = [/* your data here */];
        final data = preprocessAudio(_selectAudioFile as String);
        final inputOrt =
            OrtValueTensor.createTensorWithDataList(data as List, shape);
        final inputs = {'input': inputOrt};
        final runOptions = OrtRunOptions();
        final outputs = await session.runAsync(runOptions, inputs);

        print('The output of the shape is $outputs');

        // Release resources
        inputOrt.release();
        runOptions.release();
        outputs?.forEach((element) {
          element?.release();
        });

        return outputs; //Returning output
      } finally {
        // Releasing session
        session.release();
      }
    } finally {
      // Releasing environment
      OrtEnv.instance.release();
    }
  }

  // Future<List<List<double>>> performInference() async {
  //   try {
  //     // Load model if not already loaded
  //     if (_ortSession == null) {
  //       OrtEnv.instance.init();
  //       const assetFileName = 'assets/models/chainsaw_detection.onnx';
  //       final rawAssetFile = await rootBundle.load(assetFileName);
  //       final bytes = rawAssetFile.buffer.asUint8List();

  //       final sessionOptions =
  //           OrtSessionOptions(); // If needed, customize options here

  //       _ortSession = OrtSession.fromBuffer(bytes, sessionOptions);
  //     }

  //     if (_ortSession == null) {
  //       print('Failed to load the model');
  //       throw Exception('Failed to load the model.');
  //     }

  //     // // Reshape input data (assuming ecgSegment has a length of 200)
  //     // final List<List<int>> ecgSegment2D = [ecgSegment]; // Create a 2D list

  //     // // Convert to Float32List
  //     // final Float32List ecgSegmentFloat32 = Float32List.fromList(
  //     //   ecgSegment2D.expand((row) => row).map((value) => value.toDouble()).toList(),
  //     // );

  //     // Adjust your batch size if needed
  //     final shape = [4991, 257, 1];
  //     final inputOrt = OrtValueTensor.createTensorWithDataList(
  //         preprocessAudio as List, shape);
  //     final inputs = {'input_1': inputOrt};
  //     final runOptions = OrtRunOptions(); // Create run options if needed
  //     final outputs = await _ortSession!.runAsync(runOptions, inputs);
  //     inputOrt.release();
  //     runOptions.release();

  //     // Process the outputs and convert them to the desired format
  //     final List<List<double>> result = [];
  //     for (final outputData in outputs![0]?.value as List<List<List<double>>>) {
  //       for (final row in outputData) {
  //         result.add(row);
  //       }
  //     }

  //     // Release the OrtValue objects
  //     for (var element in outputs) {
  //       element?.release();
  //     }

  //     return result;
  //   } catch (e) {
  //     print('Error loading model or running inference: $e');
  //     // Rethrow the exception to propagate it
  //     throw e;
  //   }
  // }

  void _startAudioRecognition() {
    var required_output = performInference();

    print('The output from the machine learning model is $required_output');
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
