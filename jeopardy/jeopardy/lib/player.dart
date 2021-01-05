import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:jeopardy/main.dart';

class PlayerJoin extends StatelessWidget {
  Widget build(BuildContext context) {
    String gameKey;
    String name;
    return Scaffold(
        appBar: AppBar(
          title: Text("Enter game key"),
        ),
        body: Column(children: [
          TextField(
            decoration: InputDecoration(
                border: OutlineInputBorder(), labelText: "Enter game key"),
            maxLength: 4,
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) => {gameKey = value},
          ),
          TextField(
            decoration: InputDecoration(
                border: OutlineInputBorder(), labelText: "Enter name"),
            onChanged: (value) => {name = value},
          ),
          ElevatedButton(
            child: Text("Join Game"),
            onPressed: () {
              if (gameKey.isEmpty || name.isEmpty) {
                return Text("Error: Please enter your name and game key");
              }
              return Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          JoinedGame(gameKey: gameKey, name: name)));
            },
          )
        ]));
  }
}

class JoinedGame extends StatefulWidget {
  const JoinedGame({
    Key key,
    this.gameKey,
    this.name,
  }) : super(key: key);

  final String gameKey;
  final String name;

  JoinedGameState createState() => JoinedGameState();
}

class JoinedGameState extends State<JoinedGame> {
  String gameId;

  Widget handleJoining(AsyncSnapshot snapshot) {
    List<DocumentSnapshot> games = snapshot.data.docs;
    if (games.isEmpty) {
      return Text(
        "Game not found. Please try another game key",
        style: TextStyle(fontSize: 15, color: Colors.blue),
      );
    }
    if (games.length > 1) {
      return Text(
        "An error occurred. Please create a new game.",
        style: TextStyle(fontSize: 15, color: Colors.blue),
      );
    }
    setState(() {
      gameId = games[0].id;
    });
    return addPlayer();
  }

  Widget addPlayer() {
    String playerKey = generateRandomString(8);
    Future<String> success =
        FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentReference gameRef =
          FirebaseFirestore.instance.collection('games').doc(gameId);
      DocumentSnapshot snapshot = await transaction.get(gameRef);
      Map<String, dynamic> gameData = snapshot.data();
      int numPlayers = gameData['numPlayers'];
      Map<String, dynamic> playerData = gameData['players'];
      if (numPlayers == 5) {
        return 'Full';
      }
      transaction.update(gameRef, {
        'numPlayers': numPlayers + 1,
        'players': {
          ...playerData,
          playerKey: {'name': widget.name, 'score': 0}
        }
      });
      return 'Success';
    }, timeout: Duration(seconds: 10));
    return FutureBuilder<String>(
      future: success, // a previously-obtained Future<String> or null
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        Widget children;
        if (snapshot.data == 'Success') {
          children = Text(
            "You've successfully joined the game!",
            style: TextStyle(fontSize: 15, color: Colors.blue),
          );
        } else if (snapshot.data == 'Full') {
          children = Text(
            "This game is full :(",
            style: TextStyle(fontSize: 15, color: Colors.blue),
          );
        } else if (snapshot.hasError) {
          children = Column(children: <Widget>[
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Error: ${snapshot.error}'),
            )
          ]);
        } else {
          children = Column(children: <Widget>[
            SizedBox(
              child: CircularProgressIndicator(),
              width: 60,
              height: 60,
            ),
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Awaiting result...'),
            )
          ]);
        }
        return Center(
          child: children,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Waiting to start game..."),
          leading: FlatButton(
            child: Text(
              "Leave",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              //String gameId = snapshot.data.docs[0].id;
              //FirebaseFirestore.instance
              //    .collection('games')
              //    .doc(gameId)
              //    .update({'status': 'quit'});
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Center(
            child: StreamBuilder(
                stream: Stream.fromFuture(FirebaseFirestore.instance
                    .collection('games')
                    .where('key', isEqualTo: widget.gameKey.toUpperCase())
                    .where('status', isEqualTo: 'waiting')
                    .get()),
                builder: (context, snapshot) {
                  List<Widget> children;
                  if (snapshot.hasData) {
                    children = [handleJoining(snapshot)];
                  } else if (snapshot.hasError) {
                    children = <Widget>[
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text('Error: ${snapshot.error}'),
                      )
                    ];
                  } else {
                    children = <Widget>[
                      SizedBox(
                        child: CircularProgressIndicator(),
                        width: 60,
                        height: 60,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text('Searching...'),
                      )
                    ];
                  }
                  return Column(
                    children: children,
                    mainAxisAlignment: MainAxisAlignment.center,
                  );
                })));
  }
}
