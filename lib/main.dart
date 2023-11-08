import 'dart:async';

import 'package:flutter/material.dart';
import 'save_data.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'accelerometer_data.dart';
import 'gyroscope_data.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sensors Demo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const MyHomePage(title: 'Flutter Sensor Data Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final databaseReference = FirebaseDatabase.instance.ref();
  List<String> dataList = [];

  List<double>? _accelerometerValues;
  List<double>? _userAccelerometerValues;
  List<double>? _gyroscopeValues;

  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  List<double>? _accelerometerDisplay = [0, 0, 0];
  List<double>? _gyroscopeDisplay = [0, 0, 0];

  final List<AccelerometerData> _accelerometerData = [];
  final List<GyroscopeData> _gyroscopeData = [];

  String firebaseDataDisplay = '';

  int backAndForth = 0;

  bool showStopDialog = false;

  final DataSaver _dataSaver = DataSaver();

  void _showStopDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Stop?'),
          content: const Text(
              'Do you want to stop monitoring User Accelerometer data?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  showStopDialog = false;
                });
              },
            ),
          ],
        );
      },
    );
  }

  void fetchDataFromFirebase() {
    // Listen for data changes in a specific path in the database
    databaseReference.onChildAdded.listen((event) async {
      final data = event.snapshot.value;
      debugPrint('$data');
      if (data != null) {
        setState(() {
          dataList.clear(); // Clear the previous data
          firebaseDataDisplay = '$data';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // All these functions reduce the values to single decimal point and make it into a list.
    final userAccelerometer = _userAccelerometerValues
        ?.map((double v) => v.toStringAsFixed(1))
        .toList();
    final accelerometer =
        _accelerometerValues?.map((double v) => v.toStringAsFixed(1)).toList();
    final gyroscope =
        _gyroscopeValues?.map((double v) => v.toStringAsFixed(1)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Sensor Data'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(width: 1.0, color: Colors.black38),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('UserAccelerometer: $userAccelerometer'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Accelerometer: $accelerometer'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Gyroscope: $gyroscope'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Date: ${DateTime.now().toString().substring(11, 19)}'),
              ],
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  const Text('Local Storage'),
                  Text('Accelerometer: ${_streamSubscriptions[2]}}'),
                  Text('Gyrcoscope: $_gyroscopeDisplay'),
                ],
              )),
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text('Firebase Data'),
                  Text(firebaseDataDisplay),
                ],
              )),
          // a simple button to test the accelerometer
          ElevatedButton(
            child: const Text("Save data"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 5, 175, 161),
            ),
            onPressed: () {
              print("length: ${_accelerometerData.length}");
              _dataSaver.saveTextToFile(
                  "data.txt", _accelerometerValues, _gyroscopeValues);
              setState(() {
                _accelerometerDisplay = _accelerometerValues;
                _gyroscopeDisplay = _gyroscopeValues;
              });
            },
          ),
          ElevatedButton(
              onPressed: fetchDataFromFirebase,
              child: const Text('Get data from firebase'))
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    _streamSubscriptions.add(
      accelerometerEvents.listen(
        (AccelerometerEvent event) {
          setState(() {
            _accelerometerValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
    _streamSubscriptions.add(
      gyroscopeEvents.listen(
        (GyroscopeEvent event) {
          setState(() {
            _gyroscopeValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
    _streamSubscriptions.add(
      userAccelerometerEvents.listen(
        (UserAccelerometerEvent event) {
          setState(() {
            _userAccelerometerValues = <double>[event.x, event.y, event.z];
            List<String>? userAccelerometer = _userAccelerometerValues
                ?.map((double v) => v.toStringAsFixed(1))
                .toList();
            if ((userAccelerometer![0] == '1.0') ||
                (userAccelerometer![0] == '-1.0')) {
              debugPrint((userAccelerometer[0] == '-0.0').toString());
              debugPrint((userAccelerometer[1] != '0.0').toString());
              debugPrint((userAccelerometer[2] != '0.0').toString());
              setState(() {
                showStopDialog = true;
              });
              _showStopDialog();
            }
          });
        },
      ),
    );
  }
}
