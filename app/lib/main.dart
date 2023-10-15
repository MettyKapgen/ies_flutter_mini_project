//ignore_for_file: prefer_const_constructors

import 'dart:convert';

import 'package:app/Coord.dart';
import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';

@pragma(
    'vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    print("Native called background task: $task");
    return Future.value(true);
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
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
        SizedBox(
            height: 700,
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
                      "Received: " +
                          "Lat: " +
                          apiResponse[index].Lat.toStringAsFixed(2) +
                          " Lon: " +
                          apiResponse[index].Lon.toStringAsFixed(2),
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                      "Current: " +
                          "Lat: " +
                          position.latitude.toStringAsFixed(2) +
                          " Lon: " +
                          position.longitude.toStringAsFixed(2),
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                      "Returned: " +
                          "Lat: " +
                          apiReturn[index].Lon.toStringAsFixed(2) +
                          " Lon: " +
                          apiReturn[index].Lat.toStringAsFixed(2),
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

  @override
  void initState() {
    super.initState();
    //Cancel all Backgroundtask
    Workmanager().cancelAll();
    //Workmanager().registerOneOffTask("testtask", "backUp",
    //    initialDelay: Duration(seconds: 2));
  }
}

/*

### Function to differentiate between to Widgets
### Not needed for this project
  Widget getApiWidget() {
    if (apiCall) {
      return CircularProgressIndicator(
        color: Color.fromRGBO(255, 255, 255, 50),
      );
    } else {
      return ListView.builder(
        itemCount: apiResponse.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              "API: " +
                  apiResponse[index].userId.toString() +
                  ", Current Lat: " +
                  "${position.latitude}" +
                  ", Current Lon: " +
                  "${position.longitude}" +
                  "RETURN",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      );
    }
  }
*/

/*

##############################
INITIAL APP THAT WAS GENERATED
##############################

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
*/