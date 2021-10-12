library finite_state_machine;

// Vide:
// https://stackoverflow.com/questions/56506392/how-do-i-add-an-example-project-to-a-flutter-package
// https://dart.dev/guides/libraries/create-library-packages

/// The base class for prpoerties for the FSM.  Every property set must implement at least these
class FsmProperties<States> {
  /// Notifies the client when the machine is about to enter a state, and gives it the opportunity to redirect to another state
  /// 
  /// Return null to accept proposed state, or some other state to redirect
  final States? Function()? onEnterState;
  /// Notifies the client when the machine is about to exit the current state
  final void Function()? onExitState;

  FsmProperties({this.onEnterState, this.onExitState});
}

/// A class that implements a finite state machine
///
/// At each point in time, the machine is in exactly one state. The machine transitions from state to state as directed by its client.
/// At each state, there is an associated set of properties, which the machine exposes.
class FSM<States, Properties extends FsmProperties> {
  /// Maps machine states to properties
  final Map<States, Properties> machine;
  States? _currentState;
  /// Notifies the client when a machine  is definitely entering another state
  final void Function (States s, Properties p)? onEnteredState;
  /// If the machine is entering a state for which no properties are available, gives the client a chance to generate the properties on-the-fly
  final Properties Function (States s) defaultProperties;
  
  FSM({required this.machine, required initialState,  this.onEnteredState, required this.defaultProperties}) {
    setState(initialState);
  }
  
  /// The state the machine is currently in
  States get currentState => _currentState!;
  /// The properties belonging to the state the machine is currently in
  Properties get values => this[_currentState!];

  /// Recover the properties associated with the current state (or defaultProperties if none)
  Properties operator [] (States s) {
    return machine [s] ?? defaultProperties (s);
  }

  /// Direct the machine to begin transitioning to the new state
  ///
  /// Follows any redirects, and then calls onEnteredState()
  void setState(States nextState) {
    machine[_currentState]?.onExitState?.call(); // First time of calling (and only first time) _currentState will be null, so no onExitState() call.
    while (true) {
      final destinationState = machine[nextState]?.onEnterState?.call();
      if ((destinationState == null) || (destinationState == nextState)) break;
      nextState = destinationState; // we're being redirected
    }
    _currentState = nextState;
    onEnteredState?.call (currentState, values);
  }
}
