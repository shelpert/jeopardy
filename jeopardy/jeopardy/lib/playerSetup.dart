import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main.dart';
import 'blocs.dart';

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
  String playerKey = generateRandomString(8);

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
    String tempGameId = games[0].id;
    return addPlayer(tempGameId);
  }

  Widget addPlayer(String tempGameId) {
    return Center(
        child: Column(children: [
      Text("Found Game " + widget.gameKey.toUpperCase()),
      ElevatedButton(
        child: Text("Join Game"),
        onPressed: () {
          FirebaseFirestore.instance.runTransaction((transaction) async {
            DocumentReference gameRef =
                FirebaseFirestore.instance.collection('games').doc(tempGameId);
            DocumentSnapshot snapshot = await transaction.get(gameRef);
            Map<String, dynamic> gameData = snapshot.data();
            int numPlayers = gameData['numPlayers'];
            Map<String, dynamic> playerData = gameData['players'];
            if (numPlayers >= 5) {
              setState(() {
                gameId = tempGameId;
              });
              return "Full";
            }
            transaction.update(gameRef, {
              'numPlayers': numPlayers + 1,
              'players': {
                ...playerData,
                playerKey: {'name': widget.name, 'score': 0}
              }
            });
            mainBloc.playerKey = playerKey;
            mainBloc.startGame(tempGameId);
          }, timeout: Duration(seconds: 10));
        },
      )
    ]));
  }

  Widget beforeJoining() {
    return FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('games')
            .where('key', isEqualTo: widget.gameKey.toUpperCase())
            .where('status', isEqualTo: 'waiting')
            .get(),
        builder: (context, snapshot) {
          Widget child;
          if (snapshot.hasData) {
            child = handleJoining(snapshot);
          } else if (snapshot.hasError) {
            child = errorWidget(snapshot.error);
          } else {
            child = loadingWidget("Loading");
          }
          return Scaffold(
              appBar: AppBar(
                title: Text("Waiting to start game..."),
              ),
              body: Center(
                child: child,
              ));
        });
  }

  Widget gameFull = Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text("This game is full :("),
      ));

  @override
  Widget build(BuildContext context) {
    return gameId == null ? beforeJoining() : gameFull;
  }
}
