import "dart:async";
import "dart:isolate";

import "ports.dart";
import "payload.dart";
import "child.dart";

import "package:meta/meta.dart";

/// A parent isolate that can spawn children isolates.
///
/// Call [init] first to prepare the parent, then use [spawn] to spawn your child isolates. Each
/// child isolate should be a subclass of [IsolateChild], and must override [IsolateChild.id] to
/// be unique from every other child that this parent will spawn. It is an error for two children
/// spawned by [spawn] to have the same ID, as it will confuse the parent.
///
/// Two-way communication is implemented by calling [send] to send some data to the child with
/// the given ID, and incoming data can be read by listening to [stream]. Be sure to call [dispose]
/// when finished with this parent to stop listening to messages and kill all isolates.
///
/// This class has two type arguments, [S] for the type being sent and [R] for the type being
/// received. To keep the logic straightforward, this parent must send the same type [S] to all
/// its children, and each child can only send messages of type [R]. If different data types
/// are desired, try making a more complex class to contain the fields you need, or make a new
/// parent to spawn children of different types.
///
/// Note that [S] and [R] will be flipped with respect to this class's children: if you send
/// integers and expect strings, then each child must expect integers and send strings.
class IsolateParent<S, R> {
  final _controller = StreamController<R>.broadcast();
  final Map<Object, TypedSendPort<S>> _sendPorts = {};
  final Map<Object, Completer<void>> _completers = {};

  /// All the isolates started by this parent.
  final Map<Object, Isolate> isolates = {};

  /// Creates an isolate that can spawn and manage other isolates.
  IsolateParent();

  TypedReceivePort<ChildIsolatePayload<R, S>>? _receiver;
  StreamSubscription<ChildIsolatePayload<R, S>>? _subscription;

  /// A stream of all incoming data from all children.
  ///
  /// This stream only includes the data the children send, not their IDs. If you need to identify
  /// each child, include their [IsolateChild.id] in the response.
  Stream<R> get stream => _controller.stream;

  /// Starts listening to potential children isolates.
  @mustCallSuper
  void init() {
    _receiver = TypedReceivePort(ReceivePort());
    _subscription = _receiver!.listen((payload) => switch (payload) {
      ChildIsolateRegistration(:final id, :final port) => _registerChild(id, port),
      ChildIsolateData(:final data) => _controller.add(data),
    },);
  }

  void _registerChild(Object id, TypedSendPort<S> port) {
    if (_sendPorts.containsKey(id)) {
      throw StateError("Received a new child isolate with a duplicate ID: $id");
    }
    _sendPorts[id] = port;
    _completers[id]?.complete();
  }

  /// Kills all isolates and clears all handlers.
  @mustCallSuper
  Future<void> dispose({int priority = Isolate.beforeNextEvent}) async {
    for (final isolate in isolates.values) {
      isolate.kill(priority: priority);
    }
    await _subscription?.cancel();
    _receiver?.close();
    _sendPorts.clear();
    isolates.clear();
  }

  /// Returns whether there is an isolate with the given [IsolateChild.id].
  bool hasChild(Object id) => isolates.containsKey(id);

  /// Kills the child isolate with the given ID and priority and forgets its [SendPort].
  ///
  /// Use [hasChild] to test if there really is a child with this ID. If not, this is a no-op.
  void killIsolate({required Object id, int priority = Isolate.beforeNextEvent}) {
    isolates.remove(id)?.kill(priority: priority);
    _sendPorts.remove(id);
  }

  /// Sends the object to the child with the given ID.
  void send({required S data, required Object id}) {
    final port = _sendPorts[id];
    if (port == null) throw ArgumentError("No child isolate found with id=$id");
    port.send(data);
  }

  /// Spawns the child and calls [IsolateChild.init] to establish two-way communication.
  Future<Isolate> spawn(IsolateChild<R, S> child) async {
    if (_receiver == null) throw StateError("You must call IsolateParent.init() before calling spawn()");
    if (isolates.containsKey(child.id)) throw ArgumentError("An isolate with ID [${child.id}] already exists");

    final completer = Completer<void>();
    _completers[child.id] = completer;
    final isolate = await Isolate.spawn<TypedSendPort<ChildIsolatePayload<R, S>>>(child.init, _receiver!.sendPort);
    isolates[child.id] = isolate;
    await completer.future;  // wait for the child to send a [ChildIsolateRegistration]
    return isolate;
  }
}
