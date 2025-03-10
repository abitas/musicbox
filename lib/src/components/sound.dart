import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../components/pcm_synthesizer.dart';
import 'music_model.dart';

//----------------synthesizer---------------------

  PcmSynthesizer pcm = PcmSynthesizer();

Uint8List generateSineWave(int sampleRate, int millisecondsDuration, double frequency) {
  int numSamples = (sampleRate * millisecondsDuration ~/ 1000);
  final ByteData byteData = ByteData(numSamples * 2); // 16-bit = 2 bytes per sample

  for (int i = 0; i < numSamples; i++) {
    double sampleValue = sin(2 * pi * frequency * i / sampleRate);
    int intSample = (sampleValue * 32767).toInt();
    byteData.setInt16(i * 2, intSample, Endian.little);
  }

  return byteData.buffer.asUint8List();
}
Uint8List generatetestPcmData(List<double> frequencies, int sampleRate, int millisecondsDuration, {int numChannels = 2}) {
  int numSamples = (sampleRate * millisecondsDuration ~/ 1000);
  final ByteData byteData = ByteData(numSamples * numChannels * 2); // 16-bit = 2 bytes per sample per channel

  for (int i = 0; i < numSamples; i++) {
    double sampleValue = 0.0;

    // Legger sammen flere frekvenser for å lage en akkord
    for (double freq in frequencies) {
      sampleValue += sin(2 * pi * freq * i / sampleRate);
    }

    // Normaliser volumet slik at det ikke overstyrer
    sampleValue /= frequencies.length;
    sampleValue *= 32767; // 16-bit PCM (-32768 til 32767)
    int intSample = sampleValue.toInt().clamp(-32768, 32767);

    // Interleaved format: L, R, L, R, ...
    for (int ch = 0; ch < numChannels; ch++) {
      byteData.setInt16((i * numChannels + ch) * 2, intSample, Endian.little);
    }
  }

  return byteData.buffer.asUint8List();
}

Uint8List generatetestPcmData1(List<double> frequencies, int sampleRate, int millisecondsDuration, {int numChannels = 2}) {
  int numSamples = (sampleRate * millisecondsDuration ~/ 1000);
  final ByteData byteData = ByteData(numSamples * numChannels * 4); // 32-bit float = 4 bytes per sample per channel

  for (int i = 0; i < numSamples; i++) {
    double sampleValue = 0;

    for (double freq in frequencies) {
      sampleValue += sin(2 * pi * freq * i / sampleRate);
    }

    sampleValue /= frequencies.length; // Normaliser
    sampleValue = sampleValue.clamp(-1.0, 1.0); // Float32 i [-1.0, 1.0]

    for (int ch = 0; ch < numChannels; ch++) {
      byteData.setInt32((i * numChannels + ch) * 4, sampleValue.toInt(), Endian.little);
    }
  }

  return byteData.buffer.asUint8List();
}

  Uint8List generatetestPcmData3(List<double> frequencies,int sampleRate,int millisecondsDuration) {
    int numSamples = (sampleRate * millisecondsDuration ~/ 1000);
    final ByteData byteData = ByteData(numSamples * 2); // 16-bit = 2 bytes per sample
    for (int i = 0; i < numSamples; i++) {
      double sampleValue = 0.0;
      // Legg sammen flere frekvenser for å lage en akkord
      for (double freq in frequencies) {
        sampleValue += sin(2 * pi * freq * i / sampleRate);
      }
      // Normaliser volumet slik at det ikke overstyres
      sampleValue /= frequencies.length;
      sampleValue *= 32767; // 16-bit PCM verdiområde (-32768 til 32767)
      // Skriv sample til PCM-bufferen
      byteData.setInt32(i * 2, sampleValue.toInt(), Endian.little);
    }
    return byteData.buffer.asUint8List();
  }

Uint8List generatetestPcmData2(List<double> frequencies, int sampleRate, int millisecondsDuration) {
  int numSamples = (sampleRate * millisecondsDuration ~/ 1000);
  final ByteData byteData = ByteData(numSamples * 2); // 16-bit = 2 bytes per sample
  double fadeLength = numSamples * 0.01; // 1% fade-in/fade-out

  for (int i = 0; i < numSamples; i++) {
    double sampleValue = 0.0;

    // Generer lyd basert på frekvensene
    for (double freq in frequencies) {
      sampleValue += sin(2 * pi * freq * i / sampleRate);
    }

    // Normalisering (unngå for høy amplitude)
    sampleValue /= sqrt(frequencies.length); // Bedre vekting

    // Påfør fade-in og fade-out for å unngå klikk
    if (i < fadeLength) {
      sampleValue *= (i / fadeLength);
    } else if (i > numSamples - fadeLength) {
      sampleValue *= ((numSamples - i) / fadeLength);
    }

    // Konverter til 16-bit PCM (-32768 til 32767)
    int intSample = (sampleValue * 32767).clamp(-32768, 32767).toInt();
    byteData.setInt16(i * 2, intSample, Endian.little);
  }

  return byteData.buffer.asUint8List();
}

//----------------ChordGroup: set of chords to start at same time, but with different durations--------------

class ChordGroup {
  int millisecondsDelay;
  Map<int,List<Chord>> chords={};

  ChordGroup(this.millisecondsDelay);

  void addSound(String instrument, double presetPartVolume, Note note) {
    int millisecondsDuration = note.millisecondsDuration;
    if (!chords.containsKey(millisecondsDuration)) {chords[millisecondsDuration] = [];}
    chords[millisecondsDuration]!.add(Chord(millisecondsDuration));
    chords[millisecondsDuration]!.last.addSound(instrument, presetPartVolume, note);
  }
}

//----------------Chord: set of notes to start at same time, with same durations--------------

class Chord {
  int millisecondsDuration;
  List<Sound> sounds = [];
  Uint8List pcmData = Uint8List(0);

  Chord(this.millisecondsDuration);

  void addSound (String instrument, double presetPartVolume, Note note) {
    sounds.add(Sound(instrument, note.soundVolume(presetPartVolume), note));
  }
}

//----------------list of notes to start at same time, with same durations--------------

class Sound {
  Note note;
  String instrument; 
  double soundVolume;
  int indexPlayer=0;

  String get soundFilePath =>'$instrument/${note.soundFileIdentity}';

  Sound(this.instrument, this.soundVolume, this.note);

  String get halfSpeedSoundFilePath {
    // second character in soundFileIdentity is an integer. Subtract nbrOctaves from this integer, and put the result in second character in soundFileIdentity
    String newFileIdent= note.soundFileIdentity;
    final int newOctave= int.parse(note.soundFileIdentity[1])+1;
    return '$instrument/${newFileIdent.replaceRange(1, 2, newOctave.toString())}';
  }
}

//--------------------preload of sound files for soloud-------------------------------------

  final Map<String, AudioSource> _soundCache = {};
  AudioSource getSound(String path) {return _soundCache[path]!;}

  Future<void> preloadSounds() async {
  try {
    // First most used sounds
    _soundCache["piano/C3"] = await SoLoud.instance.loadAsset('assets/sound/piano/C3.wav');
    _soundCache["piano/D3"] = await SoLoud.instance.loadAsset('assets/sound/piano/D3.wav');
    _soundCache["piano/E3"] = await SoLoud.instance.loadAsset('assets/sound/piano/E3.wav');
    _soundCache["piano/F3"] = await SoLoud.instance.loadAsset('assets/sound/piano/F3.wav');
    _soundCache["piano/G3"] = await SoLoud.instance.loadAsset('assets/sound/piano/G3.wav');
    _soundCache["piano/A3"] = await SoLoud.instance.loadAsset('assets/sound/piano/A3.wav');
    _soundCache["piano/B3"] = await SoLoud.instance.loadAsset('assets/sound/piano/B3.wav');
    _soundCache["piano/C3sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/C3sharp.wav');
    _soundCache["piano/D3sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/D3sharp.wav');
    _soundCache["piano/F3sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/F3sharp.wav');
    _soundCache["piano/G3sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/G3sharp.wav');
    _soundCache["piano/A3sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/A3sharp.wav');

    _soundCache["piano/C4"] = await SoLoud.instance.loadAsset('assets/sound/piano/C4.wav');
    _soundCache["piano/D4"] = await SoLoud.instance.loadAsset('assets/sound/piano/D4.wav');
    _soundCache["piano/E4"] = await SoLoud.instance.loadAsset('assets/sound/piano/E4.wav');
    _soundCache["piano/F4"] = await SoLoud.instance.loadAsset('assets/sound/piano/F4.wav');
    _soundCache["piano/G4"] = await SoLoud.instance.loadAsset('assets/sound/piano/G4.wav');
    _soundCache["piano/A4"] = await SoLoud.instance.loadAsset('assets/sound/piano/A4.wav');
    _soundCache["piano/B4"] = await SoLoud.instance.loadAsset('assets/sound/piano/B4.wav');
    _soundCache["piano/C4sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/C4sharp.wav');
    _soundCache["piano/D4sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/D4sharp.wav');
    _soundCache["piano/F4sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/F4sharp.wav');
    _soundCache["piano/G4sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/G4sharp.wav');
    _soundCache["piano/A4sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/A4sharp.wav');

    _soundCache["piano/C5"] = await SoLoud.instance.loadAsset('assets/sound/piano/C5.wav');
    _soundCache["piano/D5"] = await SoLoud.instance.loadAsset('assets/sound/piano/D5.wav');
    _soundCache["piano/E5"] = await SoLoud.instance.loadAsset('assets/sound/piano/E5.wav');
    _soundCache["piano/F5"] = await SoLoud.instance.loadAsset('assets/sound/piano/F5.wav');
    _soundCache["piano/G5"] = await SoLoud.instance.loadAsset('assets/sound/piano/G5.wav');
    _soundCache["piano/A5"] = await SoLoud.instance.loadAsset('assets/sound/piano/A5.wav');
    _soundCache["piano/B5"] = await SoLoud.instance.loadAsset('assets/sound/piano/B5.wav');
    _soundCache["piano/C5sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/C5sharp.wav');
    _soundCache["piano/D5sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/D5sharp.wav');
    _soundCache["piano/F5sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/F5sharp.wav');
    _soundCache["piano/G5sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/G5sharp.wav');
    _soundCache["piano/A5sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/A5sharp.wav');

    // then less used sounds
    _soundCache["piano/C6"] = await SoLoud.instance.loadAsset('assets/sound/piano/C6.wav');
    _soundCache["piano/D6"] = await SoLoud.instance.loadAsset('assets/sound/piano/D6.wav');
    _soundCache["piano/E6"] = await SoLoud.instance.loadAsset('assets/sound/piano/E6.wav');
    _soundCache["piano/F6"] = await SoLoud.instance.loadAsset('assets/sound/piano/F6.wav');
    _soundCache["piano/G6"] = await SoLoud.instance.loadAsset('assets/sound/piano/G6.wav');
    _soundCache["piano/A6"] = await SoLoud.instance.loadAsset('assets/sound/piano/A6.wav');
    _soundCache["piano/B6"] = await SoLoud.instance.loadAsset('assets/sound/piano/B6.wav');
    _soundCache["piano/C6sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/C6sharp.wav');
    _soundCache["piano/D6sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/D6sharp.wav');
    _soundCache["piano/F6sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/F6sharp.wav');
    _soundCache["piano/G6sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/G6sharp.wav');
    _soundCache["piano/A6sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/A6sharp.wav');

    _soundCache["piano/C7"] = await SoLoud.instance.loadAsset('assets/sound/piano/C7.wav');
    _soundCache["piano/D7"] = await SoLoud.instance.loadAsset('assets/sound/piano/D7.wav');
    _soundCache["piano/E7"] = await SoLoud.instance.loadAsset('assets/sound/piano/E7.wav');
    _soundCache["piano/F7"] = await SoLoud.instance.loadAsset('assets/sound/piano/F7.wav');
    _soundCache["piano/G7"] = await SoLoud.instance.loadAsset('assets/sound/piano/G7.wav');
    _soundCache["piano/A7"] = await SoLoud.instance.loadAsset('assets/sound/piano/A7.wav');
    _soundCache["piano/B7"] = await SoLoud.instance.loadAsset('assets/sound/piano/B7.wav');
    _soundCache["piano/C7sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/C7sharp.wav');
    _soundCache["piano/D7sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/D7sharp.wav');
    _soundCache["piano/F7sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/F7sharp.wav');
    _soundCache["piano/G7sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/G7sharp.wav');
    _soundCache["piano/A7sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/A7sharp.wav');

    _soundCache["piano/C2"] = await SoLoud.instance.loadAsset('assets/sound/piano/C2.wav');
    _soundCache["piano/D2"] = await SoLoud.instance.loadAsset('assets/sound/piano/D2.wav');
    _soundCache["piano/E2"] = await SoLoud.instance.loadAsset('assets/sound/piano/E2.wav');
    _soundCache["piano/F2"] = await SoLoud.instance.loadAsset('assets/sound/piano/F2.wav');
    _soundCache["piano/G2"] = await SoLoud.instance.loadAsset('assets/sound/piano/G2.wav');
    _soundCache["piano/A2"] = await SoLoud.instance.loadAsset('assets/sound/piano/A2.wav');
    _soundCache["piano/B2"] = await SoLoud.instance.loadAsset('assets/sound/piano/B2.wav');
    _soundCache["piano/C2sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/C2sharp.wav');
    _soundCache["piano/D2sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/D2sharp.wav');
    _soundCache["piano/F2sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/F2sharp.wav');
    _soundCache["piano/G2sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/G2sharp.wav');
    _soundCache["piano/A2sharp"] = await SoLoud.instance.loadAsset('assets/sound/piano/A2sharp.wav');
  } catch (e) {
    debugPrint("preloadSounds : $e");
  }
}
