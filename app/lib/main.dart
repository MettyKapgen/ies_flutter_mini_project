//  Metty Kapgen
import 'dart:async';
import 'dart:convert';
import 'package:app/Coord.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import "package:http/http.dart" as http;

//  Starts the app
//    Puts Workmanager in DebugMode
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  runApp(MaterialApp(
    home: Home(),
  ));
}

//  Constant naming to differentiate between periodic and once-run task
const simpleTaskKey = "workmanager.simpleTask";
const simplePeriodicTask = "workmanager.simplePeriodicTask";

//  Function to execute api call, calculations of the location and api post
//  Sheduled by the Workmanager!
Future<void> _backgroundTask() async {
  Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
  final api_get = await http.get(Uri.parse("http://10.0.2.2:5000/"));
  if (api_get.statusCode == 200) {
    //  Successfully received data from api
    //  Calculate new location
    print("Response Status 200");
    final tmp = Coord.fromJson(jsonDecode(api_get.body));
    final newLat = tmp.Lat + pos.latitude;
    final newLon = tmp.Lon + pos.longitude;
    final c = Coord(userId: -1, Lat: newLat, Lon: newLon);
    print("Calculated the response coordinates");
    final api_post = await http.post(
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
    if (api_post.statusCode == 201) {
      //  Successfully posted data to the server
      print("Response Status 201");
    } else {
      //  Failed to post data to the server
      throw Exception('Fetch(Push) failed');
    }
  } else {
    //  Failed to receive data from api
    throw Exception('Fetch(Get) failed');
  }
}

//  Function called by Workmanager
//    Handles different task calls
@pragma(
    'vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case simpleTaskKey:
        await _backgroundTask();
        print("$simpleTaskKey was executed");
        break;
      case simplePeriodicTask:
        await _backgroundTask();
        print("$simplePeriodicTask was executed");
        break;
    }
    return true;
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

//  Local variables used to simulate task on button click with response on screen
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

//  Same function as _backgroudTask, but actively changes APP UI
  void get_api_data() async {
    LocationPermission permission;
    permission = await Geolocator.requestPermission();
    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final response = await http.get(Uri.parse("http://10.0.2.2:5000/"));
    if (response.statusCode == 200) {
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
    if (response.statusCode == 201) {
      return;
    } else {
      throw Exception('Fetch failed');
    }
  }

//  Widgettree
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
                },
              );
            },
            child: Text("Run task once (Workmanager)")),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(230, 125, 72, 60)),
            onPressed: () {
              print("Run task periodic");
              Workmanager().registerPeriodicTask(
                simplePeriodicTask,
                simplePeriodicTask,
                frequency: Duration(minutes: 15),
                inputData: <String, dynamic>{
                  'int': 1,
                },
              );
            },
            child:
                Text("Run task in background every 15 minutes (Workmanager)")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromRGBO(230, 125, 72, 60)),
          child: Text("Cancel all running/sheduled tasks"),
          onPressed: () async {
            await Workmanager().cancelAll();
            print('Cancel all tasks completed');
          },
        ),
        SizedBox(
            height: 400,
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
