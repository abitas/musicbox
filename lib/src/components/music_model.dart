List<String> strOctave = ['C','Csharp','D','Dsharp','E','F','Fsharp','G','Gsharp','A','Asharp','B'];
List<String> strSoundFileIdentity = ['C1','C1sharp','D1','D1sharp','E1','F1','F1sharp','G1','G1sharp','A1','A1sharp','B1','C2','C2sharp','D2','D2sharp','E2','F2','F2sharp','G2','G2sharp','A2','A2sharp','B2','C3','C3sharp','D3','D3sharp','E3','F3','F3sharp','G3','G3sharp','A3','A3sharp','B3','C4','C4sharp','D4','D4sharp','E4','F4','F4sharp','G4','G4sharp','A4','A4sharp','B4','C5','C5sharp','D5','D5sharp','E5','F5','F5sharp','G5','G5sharp','A5','A5sharp','B5','C6','C6sharp','D6','D6sharp','E6','F6','F6sharp','G6','G6sharp','A6','A6sharp','B6'];
  int speedfactor = 300;
  int measureDuration = 24;
  int get measureMillisec => measureDuration*speedfactor;

class Pitch {    // ------------------------ selve tonen --------------
  String step = 'C';
  String octave = '4';
  int alter = 0;

  Pitch(this.step,this.octave,this.alter);
}

class Note {
  int duration = 0; 
  int delay = 0;
  int volume=100;
  Pitch? pitch;

  Note ([int dely=0, int dur=500, String step = 'C',String octave = '4',int alter = 0]) {
    pitch= Pitch(step,octave,alter);
    delay=dely;
    duration=dur;
  }
  int get millisecondsDelay=> delay * speedfactor;
  int get millisecondsDuration=> duration * speedfactor;

  double soundVolume(double presetPartVolume) {
    double soundVolume = presetPartVolume*(volume/100.0);
    if (soundVolume>1.0) {soundVolume=1.0;}
    return soundVolume;
  }

  String get soundFileIdentity {
    String strNote = '${pitch!.step}${pitch!.octave}';
    if (pitch!.alter==0) {
      return strNote;
    } else {
      int index = strSoundFileIdentity.indexWhere((fileident) {return fileident==strNote;});
      return strSoundFileIdentity[index+pitch!.alter];
    }
  }

  int get soundMidiIdentity {
    Pitch x = pitch!;
    int octaveIdent= (int.parse(x.octave)+1)*12; // C Major = 60
    int index = strOctave.indexWhere((noteident) {return noteident==x.step;});
    return octaveIdent+index+x.alter;
  }

}

class Measure {
  List<Note> notes = [];
  void forEachNote(void Function(Note note) action) { for (Note note in notes) {action(note);} }
}

List<Measure> measures = [];
