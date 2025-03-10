// IPR: https://github.com/sgossner/VSCO-2-CE har hentet ned og brukt lyd-samples i VSCO-2-CE/Keys/Upright Nr1
// https://pub.dev/packages/audioplayers https://pub.dev/documentation/audioplayers/latest/ 
// https://en.wikipedia.org/wiki/Piano_key_frequencies

// IPR: https://github.com/sgossner/VSCO-2-CE har hentet ned og brukt lyd-samples i VSCO-2-CE/Keys/Upright Nr1
// https://pub.dev/packages/audioplayers https://pub.dev/documentation/audioplayers/latest/ 
// https://en.wikipedia.org/wiki/Piano_key_frequencies

import 'dart:typed_data';
import 'dart:async';
import '../components/file_handling.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../components/music_model.dart';
import '../components/sound.dart';
import '../components/pcm_synthesizer.dart';

class SoundPlayer {
  final SoLoud soloud = SoLoud.instance;
  late SystemInfo system;
  Map<int,List<Sound>> chords = {};
  late Uint8List pcmData;
  PcmSynthesizer pcm = PcmSynthesizer();

  int nbrSoundsPlayed=0;

  SoundPlayer(SystemInfo systemInfo) {
    system = systemInfo;
    initAudioPlayer();
  }

  Future<void> initAudioPlayer() async {
    await soloud.init();
    if (soloud.isInitialized) preloadSounds();
  }

  void resetSounds() {
    chords = {};
  }
  void addSound (String instrument, double presetPartVolume, Note note) {
    int startDuration=note.millisecondsDelay;
    if (!chords.containsKey(startDuration)) {chords[startDuration] = [];}
    chords[startDuration]!.add(Sound(instrument,note.soundVolume(presetPartVolume), note));
  }

  void playChords() {   // Future<void> async
    try {
      for (var entry in chords.entries) {
        if (entry.key<10) {
          playChord(entry.value);
        } else {
          Timer(Duration(milliseconds: entry.key),()=>playChord(entry.value));
        }
      }
    } catch (error) {
      debugPrint('playChords - AudioPlayer2 - $error');
    }
  }

  void playChord(List<Sound> chord) {   // Future<void> async
    try {
      initMidiChord(chord); 
      playMidiChord(pcmData);
      //playSoundFiles(chord);
    } catch (error) {
      debugPrint('playChords - AudioPlayer2 - $error');
    }
  }

  Future<void> initMidiChord(List<Sound> chord) async { // initChord(List<Sound> chord)  {
    pcmData = await pcm.createChord(chord);
  }
  Future<void> playMidiChord(Uint8List pcmData) async {
    final AudioSource source= soloud.setBufferStream();
    soloud.addAudioDataStream(source, pcmData);
    soloud.play(source);
  }
  void playSoundFiles(List<Sound> chord) { 
    for (Sound sound in chord) {playSoundFile(sound);}
  }
  Future<void> playSoundFile(Sound sound) async {  
    try {
    final AudioSource source= getSound(sound.soundFilePath);
    final handle = await soloud.play(source);
      //final AudioSource audioSource=getSound(sound.soundFilePath);
      //final handle = await soloud.play(audioSource,volume: sound.volume);
      Timer(Duration(milliseconds: sound.note.millisecondsDuration), (){soloud.stop(handle);});
      nbrSoundsPlayed+=1;
    } catch (error) {
      debugPrint('playSound - AudioPlayer2 - ${sound.soundFilePath} - $error');
    }
  }
}
