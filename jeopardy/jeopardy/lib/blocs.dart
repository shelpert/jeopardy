import 'package:flutter/material.dart';

class BloCSetting extends State {
  rebuildWidgets({VoidCallback setStates, List<State> states}) {
    if (states != null) {
      states.forEach((s) {
        if (s != null && s.mounted) s.setState(setStates ?? () {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
        "This build function will never be called. it has to be overriden here because State interface requires this");
    return null;
  }
}

class MainBloc extends BloCSetting {
  String gameId;
  bool isAlex;
  String playerKey;
  String round;
  var rootState;

  startGame(String idString) {
    rebuildWidgets(
      setStates: () {
        gameId = idString;
        round = "jeopardy_round";
      },
      states: [rootState],
    );
  }

  leaveGame() {
    rebuildWidgets(
      setStates: () {
        gameId = null;
        playerKey = null;
      },
      states: [rootState],
    );
  }
}

MainBloc mainBloc; // do not instantiate it
