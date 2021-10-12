import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:finite_state_machine/finite_state_machine.dart';

void main() {
  runApp(const MyApp());
}

/// Cluedo Mansion,  Finite State Machine style
///
/// This is a demonstration of a simple Finite State Machine.  It defines a plan of a house (which you may recognise!)
/// and it allows you to move from room to room.
/// In addition to the map itself, there are a couple of extra rooms which you may not know about,
/// and special rules to put you in those rooms and get you out again.
///
/// Apologies for the length of this.  Unfortunately, it's not easy to come up with a "trivial" state machine that's still illustrative.


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Finite State Machine demo: Cluedo',
      home: CluedoMansion(title: 'Finite State Machine demo: Cluedo'),
    );
  }
}


// To begin: here's a list of rooms in the house.  (These are the "States" which the machine goes into)
enum Room {study, hall, lounge, diningRoom, kitchen, ballroom, conservatory, billiardRoom, library, stairs, landing, dungeon}

// For each room, we need to record some information about it.
class RoomInfo extends FsmProperties<Room> { //FsmProperties <> are properties the library needs to operate.
  final String name;
  final Room? north; // For each direction we can go, where will we end up?  (In each case, another room)
  final Room? south;
  final Room? east;
  final Room? west;
  final Room? tunnel;
  final List<Widget> actions;

  RoomInfo ({
    Room? Function()? onEnterState,  // These are the properties in FsmProperties<>  We'll see them used on the landing.
    void Function()? onExitState,
    required this.name,
    this.north,
    this.south,
    this.east,
    this.west,
    this.tunnel,
    this.actions = const []
  }) : super(onEnterState: onEnterState, onExitState: onExitState);
}



class CluedoMansion extends StatefulWidget {
  const CluedoMansion({Key? key, required this.title}) : super(key: key);
  final String title;

  @override State<CluedoMansion> createState() => _CluedoMansionState();
}

class _CluedoMansionState extends State<CluedoMansion> {
  int lives = 3;

  late final machine = FSM <Room, RoomInfo> ( // And finally, the machine with the map in it!
    initialState: Room.hall,
    onEnteredState: (room, state) {
      debugPrint ("Just entered ${state.name}");
      setState ((){}); // When we enter a new room, update the screen
    },
    machine: { // This is the map of the house.
      Room.study: RoomInfo (name: 'Study',  east: Room.hall, tunnel: Room.kitchen),
      Room.hall: RoomInfo (name: 'Hall', west:Room.study, south: Room.stairs, east:Room.lounge),
      Room.lounge: RoomInfo (name: 'Lounge', south: Room.diningRoom, west:Room.stairs, tunnel: Room.conservatory),
      Room.diningRoom: RoomInfo (name: 'Dining Room', north: Room.lounge, west: Room.stairs),
      Room.kitchen: RoomInfo (name: 'Kitchen', north: Room.diningRoom, tunnel: Room.study),
      Room.ballroom: RoomInfo (name: 'Ball Room', east: Room.kitchen, north: Room.stairs, west: Room.conservatory),
      Room.conservatory: RoomInfo (name: 'Conservatory', east: Room.ballroom, tunnel: Room.lounge),
      Room.billiardRoom: RoomInfo (name: 'Billiard Room', east: Room.stairs, north: Room.library),
      Room.library: RoomInfo (name: 'Library', east: Room.stairs, south: Room.billiardRoom),
      Room.stairs: RoomInfo (name: 'Grand Staircase', north: Room.hall, south: Room.ballroom, east: Room.diningRoom, west:Room.billiardRoom, tunnel: Room.landing),
      Room.landing: RoomInfo (name: "Upstairs\n(You shouldn't be here)", tunnel: Room.stairs, onEnterState: () {
        --lives;
        if (lives == 0) return Room.dungeon; // this redirects the state from the landing  to the dungeon.
        debugPrint ('Going upstairs just cost you a life.  $lives lives left.');
        return null; // no redirection
      }),
      // Note: no definition for Dungeon.  defaultProperties will handle that.
    },
    defaultProperties: (room) => RoomInfo (
        name: "${describeEnum(room)}\n(Quiet in here, isn't it)",
        actions: [ // If we get into this state, the only way out is to teleport.  Reset the machine.
          IconButton (
              icon: const Icon (Icons.autorenew),
              onPressed: () {
                lives = 3;
                machine.setState (Room.hall);
              }
          )
        ]),
  );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cluedo Mansion"),
        actions: machine.values.actions,
      ),
      body: Stack(
        children: [
          Center (child: Text (machine.values.name, textScaleFactor: 2.5, style: const TextStyle (fontWeight: FontWeight.bold), maxLines: 2, textAlign: TextAlign.center,)),
          tunnel (toRoom: machine.values.tunnel),
          doorway (toRoom: machine.values.east, rotation: 1, alignment: Alignment.centerRight),
          doorway (toRoom: machine.values.west, rotation: 3, alignment: Alignment.centerLeft),
          doorway (toRoom: machine.values.north, alignment: Alignment.topCenter),
          doorway (toRoom: machine.values.south, alignment: Alignment.bottomCenter),
        ]
      ),
    );
  }


  Widget doorway ({Room? toRoom, required Alignment alignment, int rotation=0}) {
    if (toRoom == null) return Container ();
    return Align (
        alignment: alignment,
        child: RotatedBox(
          quarterTurns: rotation,
          child: OutlinedButton (
            onPressed: () {machine.setState (toRoom);},
            child: Text (machine [toRoom].name),
          ),
        )
    );
  }

  Widget tunnel ({Room? toRoom}) {
    if (toRoom==null) return Container();
    return Align(
      alignment: Alignment.topRight,
      child: Transform.rotate(
        angle: -pi/4,
        alignment: Alignment.bottomRight,
        child: OutlinedButton (
          onPressed: () {machine.setState (toRoom);},
          child: Text (machine [toRoom].name, textAlign: TextAlign.center),
        ),
      ),
    );
  }

}
