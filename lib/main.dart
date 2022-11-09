import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';

const appName = 'Flutter Firebase Demo';
late Future initFuture;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: appName, debugShowCheckedModeBanner: false, theme: ThemeData.light(), darkTheme: ThemeData.dark(), home: const FirebaseDemoHome(title: appName));
  }
}

class FirebaseDemoHome extends StatefulWidget {
  const FirebaseDemoHome({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<FirebaseDemoHome> createState() => _FirebaseDemoHomeState();
}

class _FirebaseDemoHomeState extends State<FirebaseDemoHome> {
  late DatabaseReference _recordsRef;
  late bool isLoggedIn;

  final ScrollController _scrollController = ScrollController();

  // https://www.raywenderlich.com/24346128-firebase-realtime-database-tutorial-for-flutter
  Query getRecordsQuery() {
    return _recordsRef;
  }

  // Initialize the Config class (loading data) for the FutureBuilder
  Future<bool> initializeApp() async {
    print('HomePage: initializeApp()');
    // Initialize the Records database (Firebase)
    _recordsRef = FirebaseDatabase.instance.ref('records');
    return true;
  }

  void _addRecord() async {
    late String userName;
    print("Adding record");
    // TODO: Fix this ASAP
    Record record = Record(Random().nextDouble().toString(), DateTime.now().millisecondsSinceEpoch);
    try {
      await _recordsRef.push().set(record.toJson());
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  void initState() {
    print('HomePage: initState()');
    isLoggedIn = false;
    super.initState();
    initFuture = initializeApp();
  }

  Widget recordList() {
    return FirebaseAnimatedList(
      controller: _scrollController,
      query: getRecordsQuery(),
      // https://stackoverflow.com/questions/69377110/flutter-firebaseanimatedlist-assertion-error-on-push-in-sorted-list
      // https://github.com/FirebaseExtended/flutterfire/issues/7100
      sort: (a, b) {
        return a.key.toString().compareTo(b.key.toString());
      },
      itemBuilder: (context, snapshot, animation, index) {
        final json = snapshot.value as Map<dynamic, dynamic>;
        final record = Record.fromJson(json);
        var date = DateTime.fromMicrosecondsSinceEpoch(record.timestamp * 1000);
        return ListTile(
          title: Text("Message: ${record.msg}"),
          subtitle: Text("$date"),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: initFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                title: Text(widget.title),
              ),
              body: SafeArea(child: recordList()),
              floatingActionButton: FloatingActionButton(
                onPressed: _addRecord,
                tooltip: 'Add Record',
                child: const Icon(Icons.add),
              ),
            );
          } else {
            // Display the initialization message
            return Scaffold(appBar: AppBar(title: Text(widget.title)), body: const SafeArea(child: Center(child: Text('Reading application data'))));
          } // if (!snapshot.hasData)
        });
  }
}

class Record {
  final String msg;
  final int timestamp;

  Record(this.msg, this.timestamp);

  Record.fromJson(Map<dynamic, dynamic> json)
      : msg = json['msg'],
        timestamp = json['timestamp'];

  Map<dynamic, dynamic> toJson() => {'msg': msg, 'timestamp': timestamp};
}
