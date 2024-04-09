import 'dart:async';
import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fft/flutter_fft.dart';
import 'package:record/record.dart';
import 'package:tflite_flutter/tflite_flutter.dart'; // Import TensorFlow Lite package

import 'LocationPage.dart';
import 'audio_list_page.dart'; // Adjust the path if necessary

void main() {
  runApp(
    const MaterialApp(
      title: 'Deforestation Detector',
      debugShowCheckedModeBanner: false,
      home: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                      builder: (context) => const AudioRecorderApp()),
                );
              },
              child: const Text('Record Audio from microphone'),
            ),
          ],
        ),
      ),
    );
  }
}

class AudioRecorderApp extends StatefulWidget {
  const AudioRecorderApp({Key? key}) : super(key: key);

  @override
  State<AudioRecorderApp> createState() => _AudioRecorderAppState();
}

class _AudioRecorderAppState extends State<AudioRecorderApp> {
  int recordDuration = 0;
  String text = '---';
  Record audioRecorder = Record();
  StreamSubscription<RecordState>? recordSub;
  RecordState recordState = RecordState.stop;
  StreamSubscription<Amplitude>? amplitudeSub;
  Amplitude? amplitude;

  FlutterFft flutterFft = FlutterFft();

  AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();

  List<FileSystemEntity> songs = [];

  int fileCounter = 0;
  late Timer recordingTimer;

  @override
  void initState() {
    recordSub = audioRecorder.onStateChanged().listen((recordStateInner) {
      setState(() {
        recordState = recordStateInner;
      });
    });

    amplitudeSub = audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
      setState(() {
        amplitude = amp;
      });
    });

    _initialize(); // Initializing audio recorder and FFT
    pickAudioSongFromInternal();

    super.initState();
  }

  @override
  void dispose() {
    recordingTimer.cancel();
    recordSub?.cancel();
    amplitudeSub?.cancel();
    audioRecorder.dispose();
    super.dispose();
  }

  _initialize() async {
    while (!(await audioRecorder.hasPermission())) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    recordingTimer = Timer(const Duration(minutes: 5), () {
      stopRecording();
    });

    // Provide the base directory path
    String basePath = 'storage/emulated/0/Music/';
    // Concatenate the base path with the formatted file name
    String filePath = basePath + getFormattedFileName(fileCounter);
    // Start recording with the dynamically generated file path
    await audioRecorder.start(
      path: filePath,
      encoder: AudioEncoder.wav,
    );

    flutterFft.startRecorder();

    flutterFft.onRecorderStateChanged.listen(
      (data) {
        if (data != null && data.length > 1) {
          // Check if data is not null and has the expected length
          setState(() {
            amplitude = Amplitude(current: data[1] as double, max: 32767.0);
          });
        }
      },
      onError: (err) {
        debugPrint("Error: $err");
      },
    );
  }

  Future<void> stopRecording() async {
    await audioRecorder.stop();
    setState(() {
      text = 'Stopped recording';
    });
    fileCounter++;

    // Perform inference after recording stops
    await performInference();
  }

  Future<void> performInference() async {
    // Load the model
    Interpreter interpreter = await Interpreter.fromAsset('model.tflite');
    interpreter.allocateTensors();

    // Assuming inference involves loading an audio file and obtaining predictions
    // Example code for audio classification

    // Provide the path to the audio file
    // Provide the base directory path
    String basePath = 'storage/emulated/0/Music/';
    // Concatenate the base path with the formatted file name
    String filePath = basePath + getFormattedFileName(fileCounter);
    // Start recording with the dynamically generated file path
    String audioFilePath = filePath;

    // Read the audio file as bytes
    List<int> audioBytes = File(audioFilePath).readAsBytesSync();

    // Prepare input tensor
    // Replace 'inputTensorIndex' and 'inputTensorShape' with your model's input tensor index and shape
    //interpreter.setInputTensors([audioBytes]);

    // Perform inference
    interpreter.invoke();

    // Get output tensor
    // Replace 'outputTensorIndex' and 'outputTensorShape' with your model's output tensor index and shape
    List output = interpreter.getOutputTensors();
    var predictions = output[0]; // Assuming only one output tensor

    // Process model outputs here
    // For example, check if the prediction is above a certain threshold
    double threshold = 0.5; // Adjust this threshold as per your model's output
    if (predictions[0] > threshold) {
      // The model predicts the presence of deforestation sounds
      // Send a positive message
      composeEmailMessage('Deforestation detected');
    }
  }

  void composeEmailMessage(String prediction) {
    // Compose email message based on prediction
    String emailMessage = 'Prediction: $prediction';

    // Use mailer package or similar to send email
    // Configure sender, recipient, subject, body, etc.
    // sendEmail(emailMessage);
  }

  void sendEmail(String message) {
    // Implement email sending logic here
    // Example using mailer package
    // Configure SMTP server, sender, recipient, subject, body, etc.
    // Replace placeholders with actual email credentials and details
    // Here's a basic example:
    // final Email email = Email(
    // final subject = 'Prediction Results';
    // final recipients = ['recipient@example.com'];
    // final body = message;
    // final email = Email(
    //   body: body,
    //   subject: subject,
    //   recipients: recipients,
    //   isHTML: false, // Set to true if using HTML content
    // );

    // try {
    //   await FlutterEmailSender.send(email);
    //   print('Email sent successfully');
    // } catch (error) {
    //   print('Error sending email: $error');
    // }
    // }
  }

  void pickAudioSongFromInternal() {
    Directory dir = Directory('/storage/emulated/0/Music');
    List<FileSystemEntity> files;
    files = dir.listSync(recursive: true, followLinks: false);
    for (FileSystemEntity entity in files) {
      String path = entity.path;
      if (path.endsWith('.mp3') || path.endsWith('.wav')) {
        songs.add(entity);
      }
    }

    // Generate file names if there are no songs yet
    if (songs.isEmpty) {
      for (int i = 0; i < 111111112; i++) {
        String fileName = getFormattedFileName(i);
        File newFile = File('${dir.path}/$fileName');
        if (!newFile.existsSync()) {
          // Stop generating file names once the first non-existing file is found
          break;
        }
        songs.add(newFile);
      }
    }

    setState(() {});
  }

  String getFormattedFileName(int number) {
    // Format the number with leading zeros
    return '${number.toString().padLeft(10, '0')}.wav';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recorder and Player'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(text),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              amplitude != null
                  ? Text('Amplitude: ${amplitude!.current}')
                  : const Text('Amplitude: null'),
              Text('Record State: $recordState'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () async {
                  if (await audioRecorder.hasPermission()) {
                    setState(() {
                      text = 'Recording audio...';
                    });
                    await audioRecorder.start(
                      path:
                          'storage/emulated/0/Music/${getFormattedFileName(fileCounter)}',
                      encoder: AudioEncoder.wav,
                    );
                  }
                },
                child: const Text('Start Recording Audio'),
              ),
              OutlinedButton(
                onPressed: () async {
                  recordingTimer.cancel();
                  await stopRecording();
                },
                child: const Text('Stop Recording Audio'),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () async {
                  setState(() {
                    text = 'Playing audio...';
                  });

                  // Assuming you have a variable that stores the path of the most recent recording
                  String mostRecentRecordingPath =
                      'storage/emulated/0/Music/${getFormattedFileName(fileCounter)}';

                  // Check if the file exists before attempting to play
                  if (await File(mostRecentRecordingPath).exists()) {
                    Audio audio = Audio.file(
                      mostRecentRecordingPath,
                      metas: Metas(
                        title: getFormattedFileName(
                            fileCounter), // Replace with the actual title
                        //artist: 'Artist Name', // Replace with the actual artist
                      ),
                    );

                    await assetsAudioPlayer.open(audio);

                    assetsAudioPlayer.play();
                  } else {
                    print('File does not exist: $mostRecentRecordingPath');
                  }
                },
                child: const Text('Play Audio'),
              ),
              OutlinedButton(
                onPressed: () async {
                  setState(() {
                    text = 'Stopped audio!';
                  });
                  await assetsAudioPlayer.stop();
                },
                child: const Text('Stop Audio'),
              ),
            ],
          ),
          OutlinedButton(
            onPressed: () {
              setState(() {
                text = 'assetsAudioPlayer: ${assetsAudioPlayer.id}';
              });
            },
            child: const Text('Print'),
          ),
          OutlinedButton(
            onPressed: () {
              // Navigate to the LocationPage when the button is pressed
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LocationPage()),
              );
            },
            child: const Text('Get Device Location'),
          ),
          OutlinedButton(
            onPressed: () {
              pickAudioSongFromInternal();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AudioListPage(songs: songs),
                ),
              );
            },
            child: const Text('Fetch & Play Audios'),
          ),
        ],
      ),
    );
  }
}
