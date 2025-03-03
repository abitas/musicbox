// IPR: https://github.com/sgossner/VSCO-2-CE har hentet ned og brukt lyd-samples i VSCO-2-CE/Keys/Upright Nr1
// https://pub.dev/packages/audioplayers https://pub.dev/documentation/audioplayers/latest/ 
// https://en.wikipedia.org/wiki/Piano_key_frequencies

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
  double relativePlaySpeed = 1;
  late String soundFilePath; 
  double volume;
  int millisecondsDuration;

  void changeSoundFileIdentity(int nbrOctaves) {
    // second character in soundFileIdentity is an integer. Subtract nbrOctaves from this integer, and put the result in second character in soundFileIdentity
    final octave=soundFileIdentity[1];
    if (octave=='6') {return;}
    if (octave=='5') {nbrOctaves=1;}
    final int newOctave= int.parse(octave)+nbrOctaves;
    soundFileIdentity = soundFileIdentity.replaceRange(1, 2, newOctave.toString());
    relativePlaySpeed= 1.0/(nbrOctaves*2.0);
  }

  Sound(this.instrument,this.soundFileIdentity,this.volume,this.millisecondsDuration) {
    if (millisecondsDuration>1000) {changeSoundFileIdentity(1);}
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
    if (SoLoud.instance.isInitialized) preloadSounds();
  }

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

void preloadSound(String path) async {
  try {
    if (!_soundCache.containsKey(path)) {
      final AudioSource sound = await SoLoud.instance.loadAsset('assets/sound/$path.wav');
      _soundCache[path] = sound; 
    }
  } catch (e) {
    debugPrint("preloadSound : $e");
   }
}
AudioSource _getSound(String path) {return _soundCache[path]!;}

Future<AudioSource> _loadSound(String path) async {
  try {
    preloadSound(path);
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
      await SoLoud.instance.play(sound,volume: volume);
    } catch (error) {
      debugPrint('playSingleSound - AudioPlayer2 - Feil under avspilling av $note: $error');
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
      final soloud = SoLoud.instance;
      final AudioSource audioSource=_getSound(sound.soundFilePath);
      final handle = await soloud.play(audioSource,volume: sound.volume);
      if (sound.relativePlaySpeed<0.9) {soloud.setRelativePlaySpeed(handle, sound.relativePlaySpeed);}     
      Timer(Duration(milliseconds: sound.millisecondsDuration), (){soloud.stop(handle);});
      nbrSoundsPlayed+=1;
    } catch (error) {
      debugPrint('playSound - AudioPlayer2 - ${sound.soundFilePath} - $error');
    }
  }
}
