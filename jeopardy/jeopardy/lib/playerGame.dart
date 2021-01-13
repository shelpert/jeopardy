import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'blocs.dart';
import 'alexGame.dart';

class PlayerGameHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DocumentSnapshot snapshot = Provider.of<DocumentSnapshot>(context);
    return Scaffold(
        appBar: AppBar(
            title: Text('Jeopardy Game Home Page'),
            leading: FlatButton(
                child: Text(
                  "Leave",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  await FirebaseFirestore.instance.runTransaction(
                      (transaction) async {
                    DocumentReference gameRef = FirebaseFirestore.instance
                        .collection('games')
                        .doc(mainBloc.gameId);
                    DocumentSnapshot snapshot = await transaction.get(gameRef);
                    Map<String, dynamic> gameData = snapshot.data();
                    int numPlayers = gameData['numPlayers'];
                    Map<String, dynamic> playerData = gameData['players'];
                    playerData
                        .removeWhere((key, value) => key == mainBloc.playerKey);
                    transaction.update(gameRef,
                        {'numPlayers': numPlayers - 1, 'players': playerData});
                    return 'Success';
                  }, timeout: Duration(seconds: 10));
                  mainBloc.leaveGame();
                })),
        body: snapshot == null
            ? loadingWidget("Loading")
            : Column(children: [
                gameMatrix(snapshot, context),
                Row(children: [Expanded(child: scoreBoard(snapshot))])
              ]));
  }
}

Widget scoreBoard(DocumentSnapshot snapshot) {
  Map<String, dynamic> data = snapshot.data();
  Map<String, dynamic> playerData = data['players'];
  List players = playerData.keys.toList();

  return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: data['numPlayers'],
      itemBuilder: (BuildContext context, int index) {
        String playerKey = players[index];
        return ListTile(
          title: Row(
            children: [
              Text(playerData[playerKey]['name']),
              Text(playerData[playerKey]['score'].toString())
            ],
          ),
        );
      });
}
