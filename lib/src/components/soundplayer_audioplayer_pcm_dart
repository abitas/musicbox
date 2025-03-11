// IPR: https://github.com/sgossner/VSCO-2-CE har hentet ned og brukt lyd-samples i VSCO-2-CE/Keys/Upright Nr1
// https://pub.dev/packages/audioplayers https://pub.dev/documentation/audioplayers/latest/ 
// https://en.wikipedia.org/wiki/Piano_key_frequencies

import 'dart:async';
import '../components/file_handling.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';  
import 'package:flutter/services.dart';
import '../components/sound.dart';
import '../components/pcm_synthesizer.dart';

class SoundPlayer {
  late SystemInfo system;
  List<AudioPlayer> player = [];
  List<bool> isPlaying = [false,false,false,false,false,false,false,false,false,false,false,false];
  Map<int,List<Sound>> chords = {};
  int nbrSoundsPlayed=0;
  late Uint8List pcmData;
  PcmSynthesizer pcm = PcmSynthesizer();
  int indexPlayer=0;

  SoundPlayer(SystemInfo systemInfo) {
    system = systemInfo;
    initAudioPlayer();
    preloadSounds();
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

  void playChords() {   // Future<void> async
    try {
      for (var entry in chords.entries) {
        if (entry.key<100) {
          playSounds(entry.value);
          //playMidiChord(entry.value);
          //playSoundFiles(entry.value);
        } else {
          Timer(Duration(milliseconds: entry.key),()=>playMidiChord(entry.value));
          //Timer(Duration(milliseconds: entry.key),()=>playSoundFiles(entry.value));
        }
      }
    } catch (error) {
      debugPrint('playChords - AudioPlayer - $error');
    }
  }
//------------------------playing midi chords-----------------------------  
  
  Future<void> playMidiChord(List<Sound> chord) async {
    pcmData = await pcm.createChord(chord);
    indexPlayer=_findFreePlayer();
    isPlaying[indexPlayer]=true;
    final BytesSource source= BytesSource(pcmData,mimeType: "audio/wav");
    player[indexPlayer].play(source);
  }

//------------------------playing midi single notes-----------------------------  

  void playSounds(List<Sound> chord) { 
    for (Sound sound in chord) {
      sound.indexPlayer =_findFreePlayer();
      isPlaying[sound.indexPlayer]=true;
      playSound(sound);
    }
  }
  Future<void> playSound(Sound sound) async {
    try {
      pcmData = await pcm.createSound(sound);
      final BytesSource source= BytesSource(pcmData,mimeType: "audio/wav");
      player[sound.indexPlayer].play(source);
      Timer(Duration(milliseconds: sound.note.millisecondsDuration), (){player[sound.indexPlayer].stop(); stoppedPlayer(sound.indexPlayer);});
      nbrSoundsPlayed+=1;
    } catch (error) {
      debugPrint('playSound - AudioPlayer ${sound.indexPlayer} - ${sound.soundFilePath} - $error');
    }
  }

//------------------------playing files-----------------------------------------  
/*
  void playSoundFiles(List<Sound> chord) { 
    for (Sound sound in chord) {
      sound.indexPlayer =_findFreePlayer();
      isPlaying[sound.indexPlayer]=true;
      playSoundFile(sound);
    }
  }
  void playSoundFile(Sound sound) {
    try {
      player[sound.indexPlayer].play(BytesSource(getSound(sound.soundFilePath),mimeType: "audio/wav"), volume:sound.volume);
      //player[sound.indexPlayer].play(AssetSource('sound/${sound.soundFilePath}.wav',mimeType: "audio/wav"), volume:sound.volume);
      Timer(Duration(milliseconds: sound.millisecondsDuration), (){player[sound.indexPlayer].stop(); stoppedPlayer(sound.indexPlayer);});
      nbrSoundsPlayed+=1;
    } catch (error) {
      debugPrint('playSound - AudioPlayer ${sound.indexPlayer} - ${sound.soundFilePath} - $error');
    }
  }
*/  
//------------------------------stopped player-----------------------------------
//  
  void stoppedPlayer(int index) { 
    Timer(Duration(milliseconds: 100), (){isPlaying[index]=false;});
  }

}

