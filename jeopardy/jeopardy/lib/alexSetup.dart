import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'blocs.dart';

class AlexChooseGame extends StatelessWidget {
  Widget build(BuildContext context) {
    Future<QuerySnapshot> seasons =
        FirebaseFirestore.instance.collection('seasons').get();
    return FutureBuilder<QuerySnapshot>(
        future: seasons, // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          Widget children;
          if (snapshot.hasData) {
            List<QueryDocumentSnapshot> seasonList = snapshot.data.docs;
            children = ListView.builder(
              itemBuilder: (BuildContext context, int index) =>
                  ExpandableWidget(seasonList[index]),
              itemCount: seasonList.length,
            );
          } else if (snapshot.hasError) {
            children = errorWidget(snapshot.error);
          } else {
            children = loadingWidget("Loading");
          }
          return Scaffold(
            appBar: AppBar(
              title: Text("Choose an episode"),
            ),
            body: Center(
              child: Center(
                child: children,
              ),
            ),
          );
        });
  }
}

class ExpandableWidget extends StatelessWidget {
  final QueryDocumentSnapshot season;

  ExpandableWidget(this.season);

  @override
  Widget build(BuildContext context) {
    String ref = season.reference.id;
    Future<QuerySnapshot> episodes = FirebaseFirestore.instance
        .collection('seasons')
        .doc(ref)
        .collection('episodes')
        .get();
    return FutureBuilder<QuerySnapshot>(
      future: episodes, // a previously-obtained Future<String> or null
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        Widget children;
        if (snapshot.hasData) {
          List<QueryDocumentSnapshot> episodeList = snapshot.data.docs;
          if (episodeList.length == 0) return ListTile(title: Text(season.id));
          return ExpansionTile(
            key: PageStorageKey<String>(season.id),
            title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(season.id,
                      style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                  Text(season.data()['years']),
                ]),
            children: episodeList
                .map<Widget>((episode) => showEpisodes(episode, context))
                .toList(),
          );
        } else if (snapshot.hasError) {
          children = errorWidget(snapshot.error);
        } else {
          children = loadingWidget("Loading");
        }
        return Center(
          child: children,
        );
      },
    );
  }
}

showEpisodes(QueryDocumentSnapshot episode, BuildContext context) {
  Map<String, dynamic> episodeInfo = episode.data();
  return ListTile(
    key: PageStorageKey<String>(episode.id),
    title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(episodeInfo['number'].toString(),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: Colors.black)),
          Text(episodeInfo['date']),
        ]),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GameDetails(episodeInfo)),
    ),
    subtitle:
        episodeInfo['details'] == '' ? null : Text(episodeInfo['details']),
  );
}

class GameDetails extends StatelessWidget {
  final Map<String, dynamic> episodeInfo;

  GameDetails(this.episodeInfo);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Episode Details"),
        ),
        body: displayDetails(episodeInfo, context));
  }
}

Widget displayDetails(Map<String, dynamic> episodeInfo, BuildContext context) {
  double headerSize = 25;
  TextStyle headerStyle = TextStyle(
      fontSize: headerSize, fontWeight: FontWeight.bold, color: Colors.blue);
  TextStyle missingHeaderStyle = TextStyle(
      fontSize: headerSize, fontWeight: FontWeight.bold, color: Colors.red);
  TextStyle lesserStyle = TextStyle(fontSize: 20);

  List<Widget> jeopardyCategories = episodeInfo['categories']['jeopardy_round']
      .map<Widget>((category) => Text(
            category,
            style: lesserStyle,
          ))
      .toList();
  List<Widget> doubleJeopardyCategories =
      episodeInfo['categories']['double_jeopardy_round']
          .map<Widget>((category) => Text(
                category,
                style: lesserStyle,
              ))
          .toList();

  List<Widget> children = [
    Text("Jeopardy Categories", style: headerStyle),
    SizedBox(
      height: 5,
    )
  ];
  children.addAll(jeopardyCategories);
  children.addAll([
    SizedBox(
      height: 10,
    ),
    Text(
      "Double Jeopardy Categories",
      style: headerStyle,
    ),
    SizedBox(
      height: 5,
    )
  ]);
  children.addAll(doubleJeopardyCategories);
  children.addAll([
    SizedBox(
      height: 10,
    ),
    Text(
      "Final Jeopardy Category",
      style: headerStyle,
    ),
    SizedBox(
      height: 5,
    ),
    Text(
      episodeInfo['categories']['final_jeopardy_round'],
      style: lesserStyle,
    )
  ]);
  List<Widget> missing = [
    SizedBox(
      height: 10,
    ),
    Text("Missing", style: missingHeaderStyle),
    SizedBox(
      height: 5,
    ),
  ];
  List missingCategories = episodeInfo['missing'].keys.toList();
  for (int i = 0; i < missingCategories.length; i++) {
    List missingQuestions = episodeInfo['missing'][missingCategories[i]];
    String missingValues = missingCategories[i] + ' - ';
    for (int j = 0; j < missingQuestions.length; j++) {
      missingValues += missingQuestions[j].toString();
      if (j < missingQuestions.length - 1) {
        missingValues += ', ';
      }
    }
    missing.add(Text(missingValues, style: lesserStyle));
  }
  children.addAll(missing);
  children.add(SizedBox(
    height: 15,
  ));
  Widget selectButton = RaisedButton(
    child: Text("Create Game"),
    onPressed: () => Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => CreatedGame(episodeInfo))),
    color: Colors.green,
    textColor: Colors.white,
  );
  children.add(selectButton);
  return SingleChildScrollView(
      child: Center(
          child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: children,
  )));
}

String createNewGame(Map<String, dynamic> episodeInfo) {
  String key = generateRandomString(4);
  String now = DateTime.now().toString();
  String docId = now + key;
  episodeInfo['key'] = key;
  episodeInfo['status'] = 'waiting';
  episodeInfo['numPlayers'] = 0;
  episodeInfo['players'] = {};
  FirebaseFirestore.instance.collection('games').doc(docId).set(episodeInfo);
  return docId;
}

class CreatedGame extends StatelessWidget {
  final Map<String, dynamic> episodeInfo;

  CreatedGame(this.episodeInfo);

  @override
  Widget build(BuildContext context) {
    String docId = createNewGame(episodeInfo);
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('games')
            .doc(docId)
            .snapshots(),
        builder: (context, snapshot) {
          Widget child;
          if (snapshot.hasData) {
            Map<String, dynamic> playerData = snapshot.data['players'];
            String gameKey = snapshot.data['key'];
            List<Widget> players = [];
            if (playerData.isEmpty) {
              players.add(Text("No one has joined yet"));
            } else {
              List playerKeys = playerData.keys.toList();
              for (int i = 0; i < playerKeys.length; i++) {
                players.add(
                    Text(playerData[playerKeys[i]]['name'] + ' has joined!'));
              }
            }
            List<Widget> children = <Widget>[
              Text(
                "Your game key is: " + gameKey,
                style: TextStyle(fontSize: 15, color: Colors.blue),
              )
            ];
            children.addAll(players);
            children.add(ElevatedButton(
              child: Text("Start game!"),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('games')
                    .doc(docId)
                    .update({'status': 'playing'});
                mainBloc.startGame(docId);
              },
            ));
            child = Column(
              children: children,
              mainAxisAlignment: MainAxisAlignment.center,
            );
          } else if (snapshot.hasError) {
            child = errorWidget(snapshot.error);
          } else {
            child = loadingWidget("Loading");
          }
          return Scaffold(
              appBar: AppBar(
                title: Text("Waiting to start game..."),
                leading: FlatButton(
                  child: Text(
                    "Leave",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('games')
                        .doc(docId)
                        .update({'status': 'quit'});
                    Navigator.of(context).pop();
                  },
                ),
              ),
              body: Center(child: child));
        });
  }
}
