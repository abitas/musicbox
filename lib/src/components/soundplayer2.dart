// IPR: https://github.com/sgossner/VSCO-2-CE har hentet ned og brukt lyd-samples i VSCO-2-CE/Keys/Upright Nr1
// https://pub.dev/packages/audioplayers https://pub.dev/documentation/audioplayers/latest/ 
// https://en.wikipedia.org/wiki/Piano_key_frequencies

import 'dart:async';
import '../components/file_handling.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../components/music_model.dart';

class Sound {
  String instrument; 
  String soundFileIdentity; 
  late String soundFilePath; 
  double volume;
  int millisecondsDuration;

  Sound(this.instrument,this.soundFileIdentity,this.volume,this.millisecondsDuration) {
    soundFilePath='$instrument/$soundFileIdentity';
  }
}

class SoundPlayer {
  late SystemInfo system;
  Map<int,List<Sound>> chords = {};
  final Map<String, AudioSource> _soundCache = {};
  int nbrSoundsPlayed=0;

  SoundPlayer(SystemInfo systemInfo) {
    system = systemInfo;
    initAudioPlayer();
  }

  Future<void> initAudioPlayer() async {
    await SoLoud.instance.init();
    if (SoLoud.instance.isInitialized) await preloadSounds();
  }

  Future<void> preloadSounds() async {
    await preloadSound("piano/C2");
    await preloadSound("piano/D2");
    await preloadSound("piano/E2");
    await preloadSound("piano/F2");
    await preloadSound("piano/G2");
    await preloadSound("piano/A2");
    await preloadSound("piano/B2");
    await preloadSound("piano/C3");
    await preloadSound("piano/D3");
    await preloadSound("piano/E3");
    await preloadSound("piano/F3");
    await preloadSound("piano/G3");
    await preloadSound("piano/A3");
    await preloadSound("piano/B3");
    await preloadSound("piano/C4");
    await preloadSound("piano/D4");
    await preloadSound("piano/E4");
    await preloadSound("piano/F4");
    await preloadSound("piano/G4");
    await preloadSound("piano/A4");
    await preloadSound("piano/B4");
    await preloadSound("piano/C5");
    await preloadSound("piano/D5");
    await preloadSound("piano/E5");
    await preloadSound("piano/F5");
    await preloadSound("piano/G5");
    await preloadSound("piano/A5");
    await preloadSound("piano/B5");
    await preloadSound("piano/C6");
    await preloadSound("piano/D5");

    await preloadSound("piano/C3sharp");
    await preloadSound("piano/C4sharp");
    await preloadSound("piano/C5sharp");
    await preloadSound("piano/D3sharp");
    await preloadSound("piano/D4sharp");
    await preloadSound("piano/D5sharp");
    await preloadSound("piano/F3sharp");
    await preloadSound("piano/F4sharp");
    await preloadSound("piano/A2sharp");
    await preloadSound("piano/A3sharp");
    await preloadSound("piano/A4sharp");
}

Future<void> preloadSound(String path) async {
  try {
    if (!_soundCache.containsKey(path)) {
      final sound = await SoLoud.instance.loadAsset('assets/sound/$path.wav');
      _soundCache[path] = sound; 
    }
  } catch (e) {
    debugPrint("preloadSound : $e");
   }
}
AudioSource _getSound(String path) {return _soundCache[path]!;}

Future<AudioSource> _loadSound(String path) async {
  try {
    await preloadSound(path);
    return _getSound(path);
  } catch (e) {
    debugPrint("_loadSound : $e");
    return _getSound('C2');
  }
}

  Future<void> playSingleSound(String instrument, String note, double volume, int millisecondsDuration) async {
    try {
      AudioSource sound = await _loadSound("$instrument/$note");
      await SoLoud.instance.disposeAllSources();
      await SoLoud.instance.play(sound);
    } catch (error) {
      debugPrint('playSound - AudioPlayer2 - Feil under avspilling av $note: $error');
    }
  }

  void resetSounds() {
    chords = {};
  }
  void addSound (String instrument, double presetPartVolume, Note note) {
    int startDuration=note.millisecondsDelay;
    if (!chords.containsKey(startDuration)) {chords[startDuration] = [];}
    chords[startDuration]!.add(Sound(instrument,note.soundFileIdentity, note.soundVolume(presetPartVolume), note.millisecondsDuration));
  }

  void playChords() {   // Future<void> async
    try {
      for (var entry in chords.entries) {
        if (entry.key<100) {
          //initChord(entry.value); 
          playChord(entry.value);
        } else {
          //(Duration(milliseconds: entry.key-50),()=>initChord(entry.value));
          Timer(Duration(milliseconds: entry.key),()=>playChord(entry.value));
        }
      }
    } catch (error) {
      debugPrint('playChords - AudioPlayer2 - $error');
    }
  }
  void initChord(List<Sound> chord) { //Future<void> initChord(List<Sound> chord) async {
      for (Sound sound in chord) {preloadSound(sound.soundFilePath);}
  }
  void playChord(List<Sound> chord) { 
    for (Sound sound in chord) {playSound(sound);}
  }
  Future<void> playSound(Sound sound) async {  
    try {
      final handle = await SoLoud.instance.play(_getSound(sound.soundFilePath));
      Timer(Duration(milliseconds: sound.millisecondsDuration), (){SoLoud.instance.stop(handle);});
      nbrSoundsPlayed+=1;
    } catch (error) {
      debugPrint('playSound - AudioPlayer2 - ${sound.soundFilePath} - $error');
    }
  }
}

