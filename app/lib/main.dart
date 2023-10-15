//ignore_for_file: prefer_const_constructors

import 'dart:convert';

import 'package:app/Coord.dart';
import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import 'package:geolocator/geolocator.dart';
import 'dart:isolate';

import 'package:workmanager/workmanager.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    //_startBackgroundTask();
    return Future.value(true);
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher);
  Workmanager().cancelAll();
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  ReceivePort _port = ReceivePort();
  @override
  void initState() {
    super.initState();
    _startBackgroundTask();
  }

  void _startBackgroundTask() {
    Isolate.spawn(_backgroundTask, _port.sendPort);
    _port.listen((message) {
      // Handle background task completion
      print('Background task completed: $message');
    });
  }

  static Future<void> _backgroundTask(SendPort sendPort) async {
    // Perform time-consuming operation here
    //BackgroundIsolateBinaryMessenger.ensureInitialized();
    //Position pos = await Geolocator.getCurrentPosition(
    //    desiredAccuracy: LocationAccuracy.high);
    final response = await http.get(Uri.parse("http://10.0.2.2:5000/"));
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      final parsedJson = jsonDecode(response.body);
      final tmp = Coord.fromJson(parsedJson);
      final newCordx = tmp.Lat + 3; //pos.latitude;
      final newCordy = tmp.Lon + 3; //pos.longitude;
      final c = Coord(userId: -1, Lat: newCordx, Lon: newCordy);
      final response2 = await http.post(
        Uri.parse("http://10.0.2.2:5000/"),
        headers: <String, String>{
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: jsonEncode(<String, String>{
          "sendId": "1",
          "lat": c.Lat.toString(),
          "lon": c.Lon.toString()
        }),
      );
      if (response2.statusCode == 201) {
        // If the server did return a 201 OK response,
        // then parse the JSON.
        print("Successful Post");
      } else {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        throw Exception('Fetch(Push) failed');
      }
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Fetch(Get) failed');
    }
    // Send result back to the main UI isolate
    sendPort.send('Background Task completed successfully!');
  }

  List<Coord> apiResponse = [];
  bool apiCall = false;
  List<Coord> apiReturn = [];
  Position position = Position(
      longitude: 0,
      latitude: 0,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0);

  void get_api_data() async {
    LocationPermission permission;
    permission = await Geolocator.requestPermission();
    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final response = await http.get(Uri.parse("http://10.0.2.2:5000/"));
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      final parsedJson = jsonDecode(response.body);
      setState(() {
        final tmp = Coord.fromJson(parsedJson);
        apiResponse.add(tmp);
        position = pos;
        apiCall = false;
        final newCordx = tmp.Lat + position.latitude;
        final newCordy = tmp.Lon + position.longitude;
        apiReturn.add(Coord(userId: -1, Lat: newCordx, Lon: newCordy));
      });
      post_api_data();
      return;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Fetch failed');
    }
  }

  void post_api_data() async {
    final response = await http.post(
      Uri.parse("http://10.0.2.2:5000/"),
      headers: <String, String>{
        "Content-Type": "application/json; charset=UTF-8",
      },
      body: jsonEncode(<String, String>{
        "sendId": "1",
        "lat": apiReturn[(apiReturn.length - 1)].Lat.toString(),
        "lon": apiReturn[(apiReturn.length - 1)].Lon.toString()
      }),
    );
    print(response.statusCode);
    if (response.statusCode == 201) {
      // If the server did return a 201 OK response,
      // then parse the JSON.
      print("Successful Post");
      return;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Fetch failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(238, 232, 200, 20),
      appBar: AppBar(
        title: Text("Mini Project App"),
        centerTitle: true,
        backgroundColor: Color.fromRGBO(113, 179, 144, 100),
      ),
      body: Column(children: [
        ElevatedButton(
            onPressed: () {
              print(_port.first.toString());
            },
            child: Text("Run task")),
        SizedBox(
            height: 500,
            child: ListView.separated(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              separatorBuilder: (context, index) {
                return Divider(
                  color: Theme.of(context).primaryColor,
                );
              },
              itemCount: apiResponse.length,
              itemBuilder: (context, index) {
                return Column(children: [
                  Text(
                      "Received: Lat: ${apiResponse[index].Lat.toStringAsFixed(2)} Lon: ${apiResponse[index].Lon.toStringAsFixed(2)}",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                      "Current: Lat: ${position.latitude.toStringAsFixed(2)} Lon: ${position.longitude.toStringAsFixed(2)}",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                      "Returned: Lat: ${apiReturn[index].Lon.toStringAsFixed(2)} Lon: ${apiReturn[index].Lat.toStringAsFixed(2)}",
                      style: TextStyle(fontWeight: FontWeight.bold))
                ]);
              },
            )),
        if (apiCall) CircularProgressIndicator()
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            apiCall = true;
          });
          get_api_data();
        },
        backgroundColor: Color.fromRGBO(230, 125, 72, 60),
        child: const Icon(Icons.add),
      ),
    );
  }
}
