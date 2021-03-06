import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'alexSetup.dart';
import 'playerSetup.dart';
import 'dart:math';
import 'blocs.dart';
import 'alexGame.dart';
import 'playerGame.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  void initState() {
    super.initState();
    mainBloc = MainBloc();
    mainBloc.rootState = this;
  }

  @override
  void dispose() {
    mainBloc = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Initialize FlutterFire
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          return Container();
        }

        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          if (mainBloc.gameId == null) {
            return MaterialApp(
              title: 'Jeopardy',
              theme: ThemeData(
                // This is the theme of your application.
                //
                // Try running your application with "flutter run". You'll see the
                // application has a blue toolbar. Then, without quitting the app, try
                // changing the primarySwatch below to Colors.green and then invoke
                // "hot reload" (press "r" in the console where you ran "flutter run",
                // or simply save your changes to "hot reload" in a Flutter IDE).
                // Notice that the counter didn't reset back to zero; the application
                // is not restarted.
                primarySwatch: Colors.blue,
              ),
              home: MyHomePage(),
              routes: <String, WidgetBuilder>{
                '/Home': (BuildContext context) => MyHomePage(),
                '/Alex1': (BuildContext context) => AlexChooseGame(),
                '/Player1': (BuildContext context) => PlayerJoin(),
              },
            );
          } else {
            return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('games')
                    .doc(mainBloc.gameId)
                    .snapshots(),
                builder: (context, snapshot) {
                  return Provider.value(
                    value: snapshot.data,
                    child: MaterialApp(
                      title: 'Jeopardy',
                      theme: ThemeData(
                        // This is the theme of your application.
                        //
                        // Try running your application with "flutter run". You'll see the
                        // application has a blue toolbar. Then, without quitting the app, try
                        // changing the primarySwatch below to Colors.green and then invoke
                        // "hot reload" (press "r" in the console where you ran "flutter run",
                        // or simply save your changes to "hot reload" in a Flutter IDE).
                        // Notice that the counter didn't reset back to zero; the application
                        // is not restarted.
                        primarySwatch: Colors.blue,
                      ),
                      home: mainBloc.isAlex ? AlexGameHome() : PlayerGameHome(),
                    ),
                  );
                });
          }
        }

        // Otherwise, show something whilst waiting for initialization to complete
        return Container();
      },
    );
  }
}

class GlobalSnapshot {
  GlobalSnapshot({@required this.snapshot});
  final DocumentSnapshot snapshot;
}

class MyHomePage extends StatelessWidget {
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
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('Jeopardy Home Page'),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You are:',
            ),
            RaisedButton(
                child: Text("Alex (Create game)"),
                onPressed: () {
                  mainBloc.isAlex = true;
                  Navigator.pushNamed(context, '/Alex1');
                }),
            RaisedButton(
                child: Text("Player (Join game)"),
                onPressed: () {
                  mainBloc.isAlex = false;
                  Navigator.pushNamed(context, '/Player1');
                }),
          ],
        ),
      ),
    );
  }
}

String generateRandomString(int len) {
  var r = Random();
  const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
  return List.generate(len, (index) => _chars[r.nextInt(_chars.length)]).join();
}

Widget errorWidget(String error) {
  return Column(children: <Widget>[
    Icon(
      Icons.error_outline,
      color: Colors.red,
      size: 60,
    ),
    Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text('Error: $error'),
    )
  ]);
}

Widget loadingWidget(String message) {
  return Column(children: <Widget>[
    SizedBox(
      child: CircularProgressIndicator(),
      width: 60,
      height: 60,
    ),
    Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(message),
    )
  ]);
}
