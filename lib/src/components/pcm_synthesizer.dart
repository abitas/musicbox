/*
https://archive.org/details/WST25FStein_00Sep22.sf2 : Steinway Model-C Soundfont 44kHz sample version , originally created by Warren S. Trachtman, and released for free on his WSTco website in September 2000. It contains only a single instrument (Acoustic Grand Piano), made from recordings of a Steinway Model-C piano from 1897

*/
import 'package:flutter/material.dart';
import 'package:dart_melty_soundfont/soundfont.dart';
import 'package:dart_melty_soundfont/dart_melty_soundfont.dart';
import 'dart:math';
import '../components/sound.dart';


class PcmSynthesizer{
  late SoundFont soundfont;
  late Synthesizer synth;
  final int sampleRate = 44100;
  final int channels = 2;
  final int blockSize = 64;
  final int maximumPolyphony = 128;

  PcmSynthesizer() {
    init();
  }

  Future<void> init() async {
    soundfont = SoundFont.fromFile("assets/soundfont/piano.sf2");
    debugPrint("SoundFont Loaded: ${soundfont.info}");

    synth = Synthesizer.load(
      soundfont,
      SynthesizerSettings(
        sampleRate: sampleRate,
        blockSize: blockSize,
        maximumPolyphony: maximumPolyphony,
        enableReverbAndChorus: true,
      ),
    );

    synth.selectPreset(channel: 0, preset: 0);
  }
  
  Future<Uint8List> createChord(List<Sound> sounds) async {
    for (var sound in sounds) {
      synth.noteOn(channel: 0, key: sound.note.soundMidiIdentity, velocity: 120);
    }
    Uint8List pcmBytes = renderPCM(synth, sounds.first.note.millisecondsDuration, sounds.first.soundVolume);
    pcmBytes = addWavHeader(pcmBytes);
    return pcmBytes;
  }

  Future<Uint8List> createSound(Sound sound) async {
    synth.noteOn(channel: 0, key: sound.note.soundMidiIdentity, velocity: 120);
    final pcmBytes = renderPCM(synth, sound.note.millisecondsDuration, sound.note.volume as double);
    final Uint8List wavBytes = addWavHeader(pcmBytes);
    return wavBytes;
  }

  Uint8List renderPCM(Synthesizer synth, int durationMs, double volume) {
    final int numFrames = (durationMs * sampleRate ~/ 1000); // Samples per ms
    final Float32List left = Float32List(numFrames);
    final Float32List right = Float32List(numFrames);  

    synth.render(left, right);

    final Uint8List pcmBuffer = Uint8List(numFrames * 4 * 2);
    final ByteData byteData = pcmBuffer.buffer.asByteData();

    for (int i = 0; i < numFrames; i++) {
      double fadeFactor = 1.0;
      // fadeFactor = 1-sin((pi / 2) * (1 - (i / numFrames))); // (i / (2*numFrames)); // Eksempel: crescendo
      fadeFactor = sin((pi / 2) * (1 - (i / numFrames))); // 1.0 - (i / (2*numFrames)); // Diminuendo
      byteData.setInt16(i * 4, (left[i] * 32767.0*volume*fadeFactor).toInt(), Endian.little);
      byteData.setInt16(i * 4 + 2, (right[i] * 32767.0*volume*fadeFactor).toInt(), Endian.little);
    }
    return pcmBuffer;
  }

/*
-----------------------------.WAV (Waveform Audio File Format)-------------------------------------------------
A .WAV (Waveform Audio File Format) file uses a specific structure in its header to store vital information about the audio data. This structured header enables software to process and play back audio streams correctly.
.WAV files can have varying audio formats, not just PCM. Pulse-code modulation (PCM) is a method used to digitally represent analog signals. It is the standard form of digital audio in computers, compact discs, digital telephony and other digital audio applications.

Positions   Sample Value         Description
1 - 4       "RIFF"               Marks the file as a riff file. Characters are each 1. byte long.
5 - 8       File size (integer)  Size of the overall file - 8 bytes, in bytes (32-bit integer). Typically, you'd fill this in after creation.
9 -12       "WAVE"               File Type Header. For our purposes, it always equals "WAVE".
13-16       "fmt "               Format chunk marker. Includes trailing null
17-20       16                   Length of format data as listed above
21-22       1                    Type of format (1 is PCM) - 2 byte integer
23-24       2                    Number of Channels - 2 byte integer
25-28       44100                Sample Rate - 32 bit integer. Common values are 44100 (CD), 48000 (DAT). Sample Rate = Number of Samples per second, or Hertz.
29-32       176400               (Sample Rate * BitsPerSample * Channels) / 8.
33-34       4                    (BitsPerSample * Channels) / 8.1 - 8 bit mono2 - 8 bit stereo/16 bit mono4 - 16 bit stereo
35-36       16                   Bits per sample
37-40       "data"               "data" chunk header. Marks the beginning of the data section.
41-44       File size (data)     Size of the data section, i.e. file size - 44 bytes header.

Reminder: The header integers are all in Least significant byte order, so the two byte channel information 0x01 0x00 are actually 0x00001 e.g. mono.
*/
  Uint8List addWavHeader(Uint8List pcmData) {
    final int byteRate = sampleRate * channels * 2;
    final int dataSize = pcmData.length;
    final int fileSize = 36 + dataSize;

    final ByteData header = ByteData(44);
    header.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    header.setUint32(4, fileSize, Endian.little);
    header.setUint32(8, 0x57415645, Endian.big); // "WAVE"
    header.setUint32(12, 0x666d7420, Endian.big); // "fmt "
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM format
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, channels * 2, Endian.little);
    header.setUint16(34, 16, Endian.little); // Bits per sample
    header.setUint32(36, 0x64617461, Endian.big); // "data"
    header.setUint32(40, dataSize, Endian.little);

    return Uint8List.fromList([...header.buffer.asUint8List(), ...pcmData]);
  }
}