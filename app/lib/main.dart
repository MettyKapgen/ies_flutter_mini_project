import 'dart:async';
import 'dart:convert';

import 'package:app/Coord.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import "package:http/http.dart" as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  runApp(MaterialApp(
    home: Home(),
  ));
}

const simpleTaskKey = "workmanager.simpleTask";
const simplePeriodicTask = "workmanager.simplePeriodicTask";
const simplePeriodic1HourTask = "workmanager.simplePeriodic1HourTask";

void _backgroundTask() async {
  //SendPort sendPort) async {
  // Perform time-consuming operation here
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
  return;
}

@pragma(
    'vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case simpleTaskKey:
        final response = await http.get(Uri.parse("http://10.0.2.2:5000/"));
        if (response.statusCode == 200) {
          // If the server did return a 200 OK response,
          // then parse the JSON.
          print("Response Status 200");
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
            print("Response Status 201");
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
        print("$simpleTaskKey was executed. inputData = $inputData");
        final prefs = await SharedPreferences.getInstance();
        prefs.setBool("test", true);
        print("Bool from prefs: ${prefs.getBool("test")}");
        break;
      case simplePeriodicTask:
        _backgroundTask();
        print("$simplePeriodicTask was executed");
        break;
      case simplePeriodic1HourTask:
        print("$simplePeriodic1HourTask was executed");
        break;
    }

    return Future.value(true);
  });
}

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
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
            style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(230, 125, 72, 60)),
            onPressed: () {
              print("Run task");
              Workmanager().registerOneOffTask(
                simpleTaskKey,
                simpleTaskKey,
                inputData: <String, dynamic>{
                  'int': 1,
                  'bool': true,
                  'double': 1.0,
                  'string': 'string',
                  'array': [1, 2, 3],
                },
              );
            },
            child: Text("Run task in background every 15 minutes")),
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
