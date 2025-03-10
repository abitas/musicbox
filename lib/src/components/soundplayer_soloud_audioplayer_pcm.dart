// IPR: https://github.com/sgossner/VSCO-2-CE har hentet ned og brukt lyd-samples i VSCO-2-CE/Keys/Upright Nr1
// https://pub.dev/packages/audioplayers https://pub.dev/documentation/audioplayers/latest/ 
// https://en.wikipedia.org/wiki/Piano_key_frequencies

import 'dart:async';
import '../components/file_handling.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';  
import 'package:flutter_soloud/flutter_soloud.dart';
import '../components/sound.dart';
import 'music_model.dart';

//----------------------------------Chords-------------------------------------
  int durationLimitPcmCalculation = 3000;
  int durationLimitHalfSoundSpeed = 1500;

  MeasureChords? previousMeasureChords;
  late MeasureChords currentMeasureChords;
  late MeasureChords nextMeasureChords;

class MeasureChords {
  Map<int,List<ChordGroup>> chordGroups={};

  void addSound (String instrument, double presetPartVolume, Note note) {
    int millisecondsDelay=note.millisecondsDelay;
    if (!chordGroups.containsKey(millisecondsDelay)) {chordGroups[millisecondsDelay] = [];}
    chordGroups[millisecondsDelay]!.add(ChordGroup(millisecondsDelay));
    chordGroups[millisecondsDelay]!.last.addSound(instrument, presetPartVolume, note);
  }
  void initChords() async {
    for (var chordGroupList in chordGroups.values) {
      for (var chordGroup in chordGroupList) {
        for (var chordList in chordGroup.chords.values) {
          for (Chord chord in chordList) {
            if (chord.millisecondsDuration>durationLimitPcmCalculation) {
              //chord.pcmData = generatetestPcmData([440.0], 44100, 1000); //, 550.0, 660.0
              chord.pcmData = await pcm.createChord(chord.sounds);
              debugPrint('created Chord ${chord.millisecondsDuration} ${DateTime.now().millisecondsSinceEpoch}');
            }
          }
        }
      }
    }
  }
}

//----------------------------------SoundPlayer-------------------------------------

class SoundPlayer {
  late SystemInfo system;
  List<AudioPlayer> player = [];
  List<bool> isPlaying = [false,false,false,false,false,false,false,false,false];
  final SoLoud soloud = SoLoud.instance;
  int nbrSoundsPlayed=0;

  SoundPlayer(SystemInfo systemInfo) {
    system = systemInfo;
    initAudioPlayer();
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
    player = [AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer()];
    if (system.platform!="android") {for (AudioPlayer playerx in player) {playerx.setPlayerMode(PlayerMode.lowLatency);}}
    await soloud.init();
    if (soloud.isInitialized) preloadSounds();
   }

  int _findFreePlayer () { 
    int index = 0;
    try {
      while (isPlaying[index]) {index+=1;}
    } catch (e) {
      isPlaying.add(true);
      player.add(AudioPlayer());
      if (system.platform!="android") {player[index].setPlayerMode(PlayerMode.lowLatency);}
      debugPrint('_findFreePlayer : add (AudioPlayer $index');
    }
    return(index);
  }

  void playChords() {   // Future<void> async
    try {
      for (var chordGroupList in currentMeasureChords.chordGroups.values) {
        for (var chordGroup in chordGroupList) {
          for (var chordList in chordGroup.chords.values) {
            for (var chord in chordList) {
            if (chordGroup.millisecondsDelay<100) {
              choosePlayer(chord);
            } else {
              Timer(Duration(milliseconds: chordGroup.millisecondsDelay),()=>choosePlayer(chord));
            }
              for (var sound in chord.sounds) {
                sound.indexPlayer = 1;
              }
            }
          }
        }
      }
    } catch (error) {
      debugPrint('playChords - AudioPlayer - $error');
    }
  }

  void choosePlayer(Chord chord) {
    if (chord.millisecondsDuration>durationLimitPcmCalculation) {
      playAudioplayerPcmChord(chord);
      //debugPrint('choose PCM Chord ${chord.millisecondsDuration} ${DateTime.now().millisecondsSinceEpoch}');
    } else if (chord.millisecondsDuration<durationLimitHalfSoundSpeed) {
      playSoloudSoundFiles(chord);
      //debugPrint('soloud Chord ${chord.millisecondsDuration} ${DateTime.now().millisecondsSinceEpoch}');
    } else {
      playSoloudHalfSpeedSoundFiles(chord);
      //debugPrint('soloud HalfSpeed Chord ${chord.millisecondsDuration} ${DateTime.now().millisecondsSinceEpoch}');
    }
  }

//------------------------playing soloud sound files -----------------------------  

  void playSoloudSoundFiles(Chord chord) { 
    for (Sound sound in chord.sounds) {playSoloudSoundFile(sound);}
  }
  Future<void> playSoloudSoundFile(Sound sound) async {  
    try {
    final AudioSource source= getSound(sound.soundFilePath);
      final handle = await soloud.play(source,volume: sound.soundVolume);
      Timer(Duration(milliseconds: sound.note.millisecondsDuration), (){soloud.stop(handle);});
      nbrSoundsPlayed+=1;
    } catch (error) {
      debugPrint('playSound - AudioPlayer2 - ${sound.soundFilePath} - $error');
    }
  }
//------------------------playing soloud HalfSpeed sound files -----------------------------  

  void playSoloudHalfSpeedSoundFiles(Chord chord) { 
    for (Sound sound in chord.sounds) {playSoloudHalfSpeedSoundFile(sound);}
  }
  Future<void> playSoloudHalfSpeedSoundFile(Sound sound) async {  
    if (sound.note.pitch!.octave=='6') return await playSoloudSoundFile(sound);
    try {
    final AudioSource source= getSound(sound.halfSpeedSoundFilePath);
      final handle = await soloud.play(source,volume: sound.soundVolume);
      soloud.setRelativePlaySpeed(handle, 0.5);
      Timer(Duration(milliseconds: sound.note.millisecondsDuration), (){soloud.stop(handle);});
      nbrSoundsPlayed+=1;
    } catch (error) {
      debugPrint('playSound - AudioPlayer2 - ${sound.soundFilePath} - $error');
    }
  }

//------------------------playing Audioplayer PCM chords-----------------------------  
  
  Future<void> playAudioplayerPcmChord(Chord chord) async {
    int indexPlayer=_findFreePlayer();
    isPlaying[indexPlayer]=true;
    final BytesSource source= BytesSource(chord.pcmData,mimeType: "audio/wav");
    debugPrint('playAudioplayerPcmChord start $indexPlayer ${DateTime.now().millisecondsSinceEpoch}');
    player[indexPlayer].play(source);
    Timer(Duration(milliseconds: chord.millisecondsDuration), (){player[indexPlayer].stop(); stoppedPlayer(indexPlayer);});
  }

//------------------------playing Soloud PCM chords-----------------------------  
  
  Future<void> playSoloudPcmChord(Chord chord) async {
    final AudioSource source= soloud.setBufferStream();
    soloud.addAudioDataStream(source, chord.pcmData);
    debugPrint('playSoloudPcmChord start');
    final handle = await soloud.play(source);
    debugPrint('playSoloudPcmChord stop');
    Timer(Duration(milliseconds: chord.millisecondsDuration), (){soloud.stop(handle);});
  }

//------------------------------stopped player-----------------------------------
//  
  void stoppedPlayer(int index) { 
    Timer(Duration(milliseconds: 100), (){isPlaying[index]=false;});
  }

}

