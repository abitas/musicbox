// IPR: https://github.com/sgossner/VSCO-2-CE har hentet ned og brukt lyd-samples i VSCO-2-CE/Keys/Upright Nr1
// https://pub.dev/packages/audioplayers https://pub.dev/documentation/audioplayers/latest/ 
// https://en.wikipedia.org/wiki/Piano_key_frequencies

import 'dart:async';
import '../components/file_handling.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';  
import 'package:flutter/services.dart';
import '../components/music_model.dart';

class Sound {
  String instrument; 
  String soundFileIdentity; 
  late String soundFilePath; 
  double volume;
  int millisecondsDuration;
  late int indexPlayer;

  Sound(this.instrument,this.soundFileIdentity,this.volume,this.millisecondsDuration) {
    soundFilePath='$instrument/$soundFileIdentity';
  }
}

class SoundPlayer {
  late SystemInfo system;
  List<AudioPlayer> player = [];
  List<bool> isPlaying = [false,false,false,false,false,false,false,false,false,false,false,false];
  Map<int,List<Sound>> chords = {};
  final Map<String, Uint8List> _soundCache = {};
  int nbrSoundsPlayed=0;

  SoundPlayer(SystemInfo systemInfo) {
    system = systemInfo;
    initAudioPlayer();
    preloadSounds();
    playTestTunes();
  }

  Future<void> initAudioPlayer() async {
    final AudioContext audioContext = AudioContext(
      iOS: AudioContextIOS(         
        category: AVAudioSessionCategory.playAndRecord,         
        options: {
          AVAudioSessionOptions.defaultToSpeaker,
          AVAudioSessionOptions.mixWithOthers,
        }
      ),       
      android: AudioContextAndroid(         
        isSpeakerphoneOn: true,         
        stayAwake: true,         
        contentType: AndroidContentType.music,         
        usageType: AndroidUsageType.virtualSource,         
        audioFocus: AndroidAudioFocus.gain,       
      ),
    );
    await AudioPlayer.global.setAudioContext(audioContext);
    player = [AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer()];
    if (system.platform!="android") {for (AudioPlayer playerx in player) {playerx.setPlayerMode(PlayerMode.lowLatency);}}
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

//--------------Test fuctionality------------------

  void playTestMeasures(int index) {   // rekursiv og Timer
    if (index>0) {
      _playTestMeasure(index);
      Timer(Duration(milliseconds: 1000),(){playTestMeasures(index-1);});
    }
  }

  Future<void> _playTestMeasure(int index) async {
    resetSounds();
    addSound("piano",0.5, Note(0,500,'C','4'));
    addSound("piano",0.5, Note(0,500,'E','4'));
    addSound("piano",0.5, Note(0,500,'G','4'));
    addSound("piano",0.5, Note(500,500,'D','4'));
    addSound("piano",0.5, Note(500,500,'F','4'));
    addSound("piano",0.5, Note(500,500,'A','4'));
    playChords();
  }

  Future<void> playTestTunes() async {
    try {
       Uint8List soundBytes = await _loadSound("piano/A2");
      for (AudioPlayer p in player) {
        await p.play(BytesSource(soundBytes,mimeType: "audio/wav"),volume:0.5);
        Timer(Duration(milliseconds: 10), (){p.stop();});
      }
    } catch (error) {
      debugPrint('playTestTunes - AudioPlayer - $error');
    }
  }

//------Functional code---------------

  int _findFreePlayer () { 
    int index = 0;
    try {
      while (isPlaying[index]) {index+=1;}
    } catch (e) {
      isPlaying.add(true);
      player.add(AudioPlayer());
      if (system.platform!="android") {player[index].setPlayerMode(PlayerMode.lowLatency);}
      debugPrint('add (AudioPlayer $index');
    }
    return(index);
  }

Future<void> preloadSound(String path) async {
  try {
    if (!_soundCache.containsKey(path)) {
      ByteData soundData = await rootBundle.load("assets/sound/$path.wav");
      _soundCache[path] = soundData.buffer.asUint8List();
    }
  } catch (e) {
    debugPrint("preloadSound : $e");
   }
}
Uint8List _getSound(String path) {return _soundCache[path]!;}

Future<Uint8List> _loadSound(String path) async {
  try {
    await preloadSound(path);
    return _getSound(path);
  } catch (e) {
    debugPrint("_loadSound : $e");
    return ByteData(0).buffer.asUint8List();
  }
}

  Future<void> playSingleSound(String instrument, String note, double volume, int millisecondsDuration) async {
    try {
      Uint8List soundBytes = await _loadSound("$instrument/$note");
      int freePlayer =_findFreePlayer();
      isPlaying[freePlayer]=true;
      await player[freePlayer].play(BytesSource(soundBytes,mimeType: "audio/wav"), volume:volume);
      Timer(Duration(milliseconds: millisecondsDuration), (){player[freePlayer].stop(); isPlaying[freePlayer]=false;});
    } catch (error) {
      debugPrint('playSound - AudioPlayer - Feil under avspilling av $note: $error');
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
      debugPrint('playChords - AudioPlayer - $error');
    }
  }
  void initChord(List<Sound> chord) { //Future<void> initChord(List<Sound> chord) async {
      for (Sound sound in chord) {
        sound.indexPlayer =_findFreePlayer();
        isPlaying[sound.indexPlayer]=true;
        //preloadSound(sound.soundFilePath); // xxx prøver uten denne 
      }
  }
  void playChord(List<Sound> chord) { 
    for (Sound sound in chord) {
      sound.indexPlayer =_findFreePlayer();
      isPlaying[sound.indexPlayer]=true;
      playSound(sound);
    }
  }
  void playSound(Sound sound) { // Future<void> async
    try {
      player[sound.indexPlayer].play(BytesSource(_getSound(sound.soundFilePath),mimeType: "audio/wav"), volume:sound.volume);
      Timer(Duration(milliseconds: sound.millisecondsDuration), (){player[sound.indexPlayer].stop(); stoppedPlayer(sound.indexPlayer);});
      nbrSoundsPlayed+=1;
    } catch (error) {
      debugPrint('playSound - AudioPlayer ${sound.indexPlayer} - ${sound.soundFilePath} - $error');
    }
  }
  void stoppedPlayer(int index) { 
    Timer(Duration(milliseconds: 100), (){isPlaying[index]=false;});
  }

}
