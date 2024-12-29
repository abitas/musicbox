import 'package:flutter/material.dart';
//import 'src/components/soundplayer.dart';
import 'src/components/soundplayer2.dart';
import 'src/components/file_handling.dart';
import 'src/components/music_model.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'package:vm_service/vm_service_io.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
//import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadMeasuresFromJson('testmeasures');
  runApp(const MyApp());
}

Future<void> loadMeasuresFromJson(String filename) async {
  final String jsonString = await rootBundle.loadString('assets/data/$filename.json');
  final List<dynamic> jsonData = jsonDecode(jsonString);

  measures = jsonData.map((measureData) {
    Measure measure = Measure();
    measure.notes = (measureData['notes'] as List<dynamic>).map((noteData) {
      return Note(
        noteData['delay'],
        noteData['duration'],
        noteData['step'],
        noteData['octave'],
        noteData['alter']
      );
    }).toList();
    return measure;
  }).toList();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abbado Music Box',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Abbado Music Box'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final SoundPlayer soundPlayer = SoundPlayer(systemInfo);
  //final SoundPlayer2 soundPlayer2 = SoundPlayer2(systemInfo);
  int _counter = 0;
  int _counter2 = 0;
  double _memoryConsumption = 0;
  Timer? _resourceMonitor;

  @override
  void initState() {
    super.initState();
    _startResourceMonitoring();
  }

  @override
  void dispose() {
    _resourceMonitor?.cancel();
    super.dispose();
  }

  void _startPlaying() {
    playMeasureIntervals(0, measures.length - 1);
  }

  void _startResourceMonitoring() {
  // need devtools to function properly, and may have problems connecting to //127.0.0.1:8181/ 
    _resourceMonitor = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final stats = await _fetchResourceStats();
      setState(() {
        _memoryConsumption = stats['memory'] ?? 0;
      });
    });
  }

  Future<Map<String, double>> _fetchResourceStats() async {
  // need devtools to function properly, and may have problems connecting to //127.0.0.1:8181/ 
    try {
      final service = await vmServiceConnectUri('ws://127.0.0.1:8181/ws');
      final vm = await service.getVM();
      final isolateRef = vm.isolates!.first;

      // Fetch memory usage
      final isolate = await service.getIsolate(isolateRef.id!);
      final memoryBytes = (isolate.json?['heapUsage'] ?? 0) as int;
      final memoryMb = memoryBytes / (1024 * 1024);

      // Fetch CPU usage (example profiling request)
      final cpuSamples = await service.getCpuSamples(isolateRef.id!, 0, DateTime.now().millisecondsSinceEpoch);
      final cpuPercent = (cpuSamples.samples?.length ?? 0) / 1000.0; // Rough estimation

      return {'memory': memoryMb, 'cpu': cpuPercent};
    } catch (e) {
      //debugPrint(e.toString());
      return {'memory': 0, 'cpu': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Add Image
            Image.asset(
              'assets/img.png',
              height: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20),
            // Display Text
            Text('Measure nbr:  $_counter',style: Theme.of(context).textTheme.headlineMedium),
            Text('Sound   nbr:  $_counter2',style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            Text(
              'Memory Consumption: ${_memoryConsumption.toStringAsFixed(2)} MB',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            // Add Buttons
            ElevatedButton(
              onPressed: () => _loadMeasuresAndUpdate('testsinglesounds',8,300),
              child: const Text('Single sounds'),
            ),
            ElevatedButton(
              onPressed: () => _loadMeasuresAndUpdate('testmeasures',8,300),
              child: const Text('Test Chords'),
            ),
            ElevatedButton(
              onPressed: () => _loadMeasuresAndUpdate('irishblessingsoprano',8,300),
              child: const Text('Irish Blessing S'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _loadMeasuresAndUpdate('irishblessing',8,300),
              child: const Text('Irish Blessing SATB'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _loadMeasuresAndUpdate('northernlights',240,15),
              child: const Text('Northern Lights SATB'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadMeasuresAndUpdate(String filename, int dur, int speed) async {
    speedfactor= speed;
    measureDuration = dur;
    await loadMeasuresFromJson(filename);
    setState(() {
      _counter = measures.length; // Display the number of loaded measures
    });
    _startPlaying();
  }

  void playMeasureIntervals(int index, int indexTo) {   // rekursiv og Timer - alternativ til forEachMeasureInterval
    if (index<=indexTo) {
      _playMeasure(index);
      Timer(Duration(milliseconds: measureMillisec),(){playMeasureIntervals(index+1, indexTo);});
    }
  }

  Future<void> _playMeasure(int index) async {
    soundPlayer.resetSounds();
    measures[index].forEachNote((Note note) {soundPlayer.addSound("piano",0.5, note);});
    soundPlayer.playChords();
    setState(() {
      _counter= index;
      _counter2= soundPlayer.nbrSoundsPlayed;
    });
  }
}
