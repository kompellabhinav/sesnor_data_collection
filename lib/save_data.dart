import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';

class DataSaver {

  Future<void> saveTextToFile(String fileName, List<double>? accelerometerData, List<double>? gyroscopeData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      IOSink sink;
      // Open the file for appending
      sink = file.openWrite(mode: FileMode.append);

      // Write data to the file
      String data = '\n\nAcceleormeter data: $accelerometerData \n Gyroscope data: $gyroscopeData';
      sink.writeln(data);
      // Close the file when you're done
      sink.close();
      
      // await file.writeAsString(data);
      print(accelerometerData);

      DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

      String accelerometerStr = '$accelerometerData';
      String gyroscopeStr = '$gyroscopeData';

      Map<String, dynamic> firebaseData = {
        'Accelerometer': accelerometerStr,
        'Gyroscope': gyroscopeStr,
      };

      databaseReference.push().set(firebaseData);

      print('File saved at: ${file.path}');
    } catch (e) {
      print('Error saving file: $e');
    }
  }
}