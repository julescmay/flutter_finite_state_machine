import 'package:flutter_test/flutter_test.dart';

import 'package:finite_state_machine/finite_state_machine.dart';

enum TestState {one, two, three}
enum ResultState {o, i, ii, iii}

class StateProperties extends FsmProperties <TestState>{
  final ResultState resultState;

  StateProperties ({
      TestState? Function()? onEnterState,  // These are the properties in FsmProperties<>  We'll see them used on the landing.
      void Function()? onExitState,
      required this.resultState,}
    ) : super (onEnterState: onEnterState, onExitState: onExitState);
}

void main() {

  test ('Machine wakes up in correct state', () {
    final machine = FSM <TestState, StateProperties> (
        defaultProperties: (s) => StateProperties (resultState: ResultState.o),
        initialState: TestState.one,
        machine: {
          TestState.one: StateProperties (resultState: ResultState.i),
        }
    );

    expect (machine.currentState, TestState.one);
    expect (machine.values.resultState, ResultState.i);
  });

  test ('Machine can transition correctly', () {
    final machine = FSM <TestState, StateProperties> (
        defaultProperties: (s) => StateProperties (resultState: ResultState.o),
        initialState: TestState.one,
        machine: {
          TestState.one: StateProperties (resultState: ResultState.i),
          TestState.two: StateProperties (resultState: ResultState.ii),
          TestState.three: StateProperties (resultState: ResultState.iii),
        }
    );

    expect (machine.currentState, TestState.one);
    expect (machine.values.resultState, ResultState.i);
    machine.setState (TestState.two);
    expect (machine.currentState, TestState.two);
    expect (machine.values.resultState, ResultState.ii);
    machine.setState (TestState.three);
    expect (machine.currentState, TestState.three);
    expect (machine.values.resultState, ResultState.iii);
  });

  test ('Machine can synthesise undefined states', () {
    final machine = FSM <TestState, StateProperties> (
        defaultProperties: (s) => StateProperties (resultState: ResultState.o),
        initialState: TestState.one,
        machine: {
        }
    );

    expect (machine.currentState, TestState.one);
    expect (machine.values.resultState, ResultState.o);
  });

  test ('Machine can redirect correctly', () {
    final machine = FSM <TestState, StateProperties> (
        defaultProperties: (s) => StateProperties (resultState: ResultState.o),
        initialState: TestState.one,
        machine: {
          TestState.one: StateProperties (resultState: ResultState.i),
          TestState.two: StateProperties (resultState: ResultState.ii, onEnterState: () => TestState.one),
          TestState.three: StateProperties (resultState: ResultState.iii, onEnterState: () => TestState.two),
        }
    );

    expect (machine.currentState, TestState.one);
    expect (machine.values.resultState, ResultState.i);
    machine.setState (TestState.two); // Should redirect to one
    expect (machine.currentState, TestState.one);
    expect (machine.values.resultState, ResultState.i);
    machine.setState (TestState.three); // Should redirect twice: to two and then one
    expect (machine.currentState, TestState.one);
    expect (machine.values.resultState, ResultState.i);
  });

  test ('Machine reports changing state correctly', () {
    TestState? lastStateReported;
    StateProperties? lastPropertiesReported;

    final machine = FSM <TestState, StateProperties> (
        defaultProperties: (s) => StateProperties (resultState: ResultState.o),
        initialState: TestState.one,
        onEnteredState: (s, pp) {
          lastStateReported = s;
          lastPropertiesReported = pp;
        },
        machine: {
          TestState.one: StateProperties (resultState: ResultState.i),
          TestState.two: StateProperties (resultState: ResultState.ii),
          TestState.three: StateProperties (resultState: ResultState.iii),
        }
    );

    expect (lastStateReported, TestState.one);
    expect (lastPropertiesReported?.resultState, ResultState.i);
    machine.setState (TestState.two);
    expect (lastStateReported, TestState.two);
    expect (lastPropertiesReported?.resultState, ResultState.ii);
    machine.setState (TestState.three);
    expect (lastStateReported, TestState.three);
    expect (lastPropertiesReported?.resultState, ResultState.iii);
  });

  test ('Machine reports exiting state correctly', () {
    ResultState? lastStateReported;

    final machine = FSM <TestState, StateProperties> (
        defaultProperties: (s) => StateProperties (resultState: ResultState.o),
        initialState: TestState.one,
        machine: {
          TestState.one: StateProperties (resultState: ResultState.i, onExitState: () {lastStateReported = ResultState.i; }),
          TestState.two: StateProperties (resultState: ResultState.ii, onExitState: () {lastStateReported = ResultState.ii; }),
          TestState.three: StateProperties (resultState: ResultState.iii, onExitState: () {lastStateReported = ResultState.iii; } ),
        }
    );

    expect (lastStateReported, null);
    machine.setState (TestState.two);
    expect (lastStateReported, ResultState.i); // We just left state one
    machine.setState (TestState.three);
    expect (lastStateReported, ResultState.ii);
  });
}
