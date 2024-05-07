import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

Future<List<int>> convertToMono(List<int> audioBytes) async {
  // Assuming 16-bit PCM (2 bytes per sample) and stereo (2 channels)
  if (audioBytes.length % 4 != 0) {
    throw Exception(
        'Invalid audio data length. Expected multiple of 4 bytes (16-bit PCM stereo)');
  }

  final numSamples = audioBytes.length ~/
      4; // Total number of samples (assuming 2 bytes per sample)

  // Create a new list for mono audio bytes (half the size of original)
  final List<int> monoAudioBytes = List<int>.generate(numSamples * 2, (i) => 0);

  // Loop through each stereo sample and average left and right channels
  for (var i = 0; i < numSamples; i++) {
    final leftSample = audioBytes[i * 4];
    final rightSample = audioBytes[i * 4 + 1];
    final monoSample = (leftSample + rightSample) ~/ 2;

    // Write the averaged sample (as a byte) to both left and right channels of mono data
    monoAudioBytes[i * 2] = monoSample;
    monoAudioBytes[i * 2 + 1] = monoSample;
  }

  return monoAudioBytes;
}

List<List<double>> getAbsoluteValuesForSTF(List<List<double>> stftData) {
  final List<List<double>> absoluteList = [];

  for (var outerList in stftData) {
    final List<double> innerAbsoluteList = [];
    for (var value in outerList) {
      innerAbsoluteList.add(value.abs());
    }
    absoluteList.add(innerAbsoluteList);
  }

  return absoluteList;
}

//To expand the dimension to the matrix of STF
List<List<List<double>>> expandDims(List<List<double>> spectrogram, int axis) {
  return List.generate(spectrogram.length, (i) {
    return List.generate(spectrogram[i].length, (j) {
      if (axis == 0) {
        return [spectrogram[i][j]];
      } else if (axis == 1) {
        return [spectrogram[i][j]];
      } else {
        return [spectrogram[i][j]];
      }
    });
  });
}

List<List<double>> stft(List<int> monoAudioBytes,
    {int frameLength = 320, int frameStep = 32}) {
  List<List<double>> spectrogram = [];

  // Convert mono audio bytes to double values (-1.0 to 1.0 range)
  List<double> signal =
      monoAudioBytes.map((byte) => byte / 127.5 - 1.0).toList();

  // Pad the signal with zeros to ensure it can be divided evenly into frames
  int numZeros = frameLength - (signal.length % frameLength);
  for (int i = 0; i < numZeros; i++) {
    signal.add(0);
  }

  // Iterate over signal frames with hop length
  for (int i = 0; i < signal.length - frameLength; i += frameStep) {
    List<double> frame = signal.sublist(i, i + frameLength);

    // Apply window function (Hann window)
    List<double> window = List.generate(frameLength,
        (index) => 0.5 * (1 - cos(2 * pi * index / (frameLength - 1))));
    for (int j = 0; j < frame.length; j++) {
      frame[j] *= window[j];
    }

    // Compute FFT of the frame
    List<double> fftResult = fft(frame);

    // Add FFT result to spectrogram
    spectrogram.add(fftResult);
  }

  return spectrogram;
}

List<double> fft(List<double> frame) {
  int N = frame.length;
  List<double> real = List.from(frame);
  List<double> imag = List.filled(N, 0.0);

  // Bit-reversal permutation
  int j = 0;
  for (int i = 0; i < N - 1; i++) {
    if (i < j) {
      double temp = real[i];
      real[i] = real[j];
      real[j] = temp;
      temp = imag[i];
      imag[i] = imag[j];
      imag[j] = temp;
    }
    int k = N ~/ 2;
    while (k <= j) {
      j -= k;
      k ~/= 2;
    }
    j += k;
  }

  // Cooley-Tukey decimation-in-time radix-2 FFT
  int m = 0;
  int n = 1;
  while (n < N) {
    m = n;
    n *= 2;
    double alpha = -2 * pi / m;
    double beta = 0.0;
    for (int i = 0; i < m; i++) {
      double wReal = cos(beta);
      double wImag = sin(beta);
      beta += alpha;
      for (int k = i; k < N; k += n) {
        int j = k + m;
        double tempReal = wReal * real[j] - wImag * imag[j];
        double tempImag = wReal * imag[j] + wImag * real[j];
        real[j] = real[k] - tempReal;
        imag[j] = imag[k] - tempImag;
        real[k] += tempReal;
        imag[k] += tempImag;
      }
    }
  }

  // Compute magnitudes
  List<double> magnitudes = List.filled(N, 0.0);
  for (int i = 0; i < N; i++) {
    magnitudes[i] = sqrt(real[i] * real[i] + imag[i] * imag[i]);
  }

  return magnitudes;
}

Future<List<List<List<double>>>> preprocessAudio(String audioFilePath) async {
  // 1. Load audio data
  var file = File(audioFilePath);
  print('The file path is $audioFilePath');
  final audioBytes = await file.readAsBytes();

  // Decode the audio bytes into WAV format
  AudioPlayer audioPlayer = AudioPlayer();
  int result = await audioPlayer.playBytes(audioBytes);

  if (result == 1) {
    print('Audio decoded successfully.');
  } else {
    print('Failed to decode audio.');
  }

  // Convert the audio to mono (squeeze )
  List<int> monoAudioBytes = await convertToMono(audioBytes);

  //Covert the data into a STF format
  final short_time_fourier_transform_variable = stft(monoAudioBytes);

  print(
      'the  short time fourier transform is $short_time_fourier_transform_variable');

  //Convert the data to absolute format
  var finalAbsoluteVariable =
      getAbsoluteValuesForSTF(short_time_fourier_transform_variable);

  print('The final absolute value is $finalAbsoluteVariable');

  //Adding extra one dimension at the end of the matrix
  List<List<List<double>>> expandedSpectrogram =
      expandDims(finalAbsoluteVariable, 2);
  print('The shape is $expandedSpectrogram');

  return expandedSpectrogram;
}
