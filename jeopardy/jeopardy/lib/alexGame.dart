import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'blocs.dart';
import 'main.dart';

class AlexGameHome extends StatelessWidget {
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
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('games')
                    .doc(mainBloc.gameId)
                    .update({'status': 'quit'});
                Navigator.of(context).pop();
              })),
      body: snapshot == null
          ? loadingWidget("Loading")
          : gameMatrix(snapshot, context),
    );
  }
}

Widget gameMatrix(DocumentSnapshot snapshot, BuildContext context) {
  String round = mainBloc.round;
  Size size = MediaQuery.of(context).size;
  Map<String, dynamic> roundData = snapshot.data()[round];
  List<Widget> matrix = [];
  List categories = roundData.keys.toList();
  for (int i = 0; i < categories.length; i++) {
    String category = categories[i];
    String categoryInfo = roundData[category]['comments'];
    Map clueInfo = roundData[category]['clues'];
    matrix.add(Column(
      children: [Text(category), Text(categoryInfo)],
    ));
    int multiplier = round == 'jeopardy_round' ? 1 : 2;
    List questions = [200, 400, 600, 800, 1000];
    Widget clues = GridView.builder(
      itemCount: 5,
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate:
          new SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
      itemBuilder: (BuildContext context, int index) {
        String questionValue = (questions[index] * multiplier).toString();
        Map questionInfo = clueInfo[questionValue];
        String display = questionInfo['done']
            ? ''
            : questionInfo['value'] == 0
                ? ''
                : questionInfo['value'].toString();
        return Card(
            child: InkResponse(
                child: Center(
                    child: Text(display,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold))),
                onTap: () {
                  !mainBloc.isAlex
                      ? null
                      : display == ''
                          ? null
                          : Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      QuestionPage(questionInfo)),
                            );
                }),
            color: Colors.blue);
      },
    );
    matrix.add(clues);
  }
  return Container(
    child: SingleChildScrollView(
        child: Column(
      children: matrix,
    )),
    height: size.height * 0.6,
  );
}

class QuestionPage extends StatelessWidget {
  final Map<String, dynamic> questionInfo;

  QuestionPage(this.questionInfo);

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
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('games')
                    .doc(mainBloc.gameId)
                    .update({'status': 'quit'});
                Navigator.of(context).pop();
              })),
      body: Text("HI"),
    );
  }
}
