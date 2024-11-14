import "dart:async";
import "dart:isolate";

import "ports.dart";
import "payload.dart";
import "child.dart";

import "package:meta/meta.dart";

/// An object in the current isolate that can spawn children isolates.
///
/// Call [init] first to prepare the parent, then use [spawn] to spawn your child isolates. Each
/// child isolate should be a subclass of [IsolateChild], and must override [IsolateChild.id] to
/// be unique from every other child that this parent will spawn. It is an error for two children
/// spawned by [spawn] to have the same ID, as it will confuse the parent.
///
/// Two-way communication is implemented by calling [sendToChild] to send some data to the child with
/// the given ID, and incoming data can be read by listening to [stream]. Be sure to call [dispose]
/// when finished with this parent to stop listening to messages and kill all isolates.
///
/// This class has two type arguments, [S] for the type being sent and [R] for the type being
/// received. Each child must send and receive the same types. If your isolates are sending wildly
/// different types, consider using a different parent for some of them. In other cases, it is a
/// common pattern to use `sealed class`es for your data types, as that allows you to make subtypes
/// with different fields, like so:
///
/// ```dart
/// sealed class ChildResponse { }
/// class ChildHasError extends ChildResponse { final String error; }
/// class ChildHasValue extends ChildResponse { final int value; }
///```
///
/// Note that [S] and [R] will be flipped with respect to this class's children: if you send
/// integers and expect strings, then each child must expect integers and send strings.
class IsolateParent<S, R> {
  /// A single [StreamController] to publish all messages from all future children.
  final _controller = StreamController<R>.broadcast();

  /// The send ports for each child.
  final Map<Object, TypedSendPort<S>> _sendPorts = {};

  /// Completers for each child that indicate when they have successfully registered.
  final Map<Object, Completer<void>> _completers = {};

  /// All the isolates started by this parent.
  final Map<Object, Isolate> _isolates = {};

  /// Creates an object in the current isolate that can spawn and manage other isolates.
  IsolateParent();

  /// The receive port for this isolate.
  TypedReceivePort<ChildIsolatePayload<R, S>>? _receiver;

  /// A subscription to [_receiver] for data from any child.
  StreamSubscription<ChildIsolatePayload<R, S>>? _subscription;

  /// A stream of all incoming data from all children.
  ///
  /// This stream only includes the data the children send, not their IDs. If you need to identify
  /// each child, include their [IsolateChild.id] in the response type [R].
  Stream<R> get stream => _controller.stream;

  /// Starts listening to potential children isolates.
  ///
  /// This must be called before any other method.
  @mustCallSuper
  void init() {
    _receiver = TypedReceivePort(ReceivePort());
    _subscription = _receiver!.stream.listen(
      (payload) => switch (payload) {
        ChildIsolateRegistration(:final id, :final port) =>
          _registerChild(id, port),
        ChildIsolateData(:final data) => _controller.add(data),
      },
    );
  }

  /// Kills all isolates and clears all handlers.
  ///
  /// See [Isolate.kill] for an explanation on [priority].
  @mustCallSuper
  Future<void> dispose({int priority = Isolate.beforeNextEvent}) async {
    for (final isolate in _isolates.values) {
      isolate.kill(priority: priority);
    }
    await _subscription?.cancel();
    _receiver?.close();
    _sendPorts.clear();
    _isolates.clear();
    _completers.clear();
  }

  /// Associates the given port with the given ID and completes the child's [Completer].
  void _registerChild(Object id, TypedSendPort<S> port) {
    if (_sendPorts.containsKey(id)) {
      throw StateError("Received a new child isolate with a duplicate ID: $id");
    }
    _sendPorts[id] = port;
    _completers[id]?.complete();
  }

  /// Returns whether this parent has spawned an isolate with the given [IsolateChild.id].
  bool hasChild(Object id) => _isolates.containsKey(id);

  /// Kills the child isolate with the given ID and priority and forgets its [SendPort].
  ///
  /// Use [hasChild] to test if there really is a child with this ID. If not, this is a no-op.
  /// See [Isolate.kill] for an explanation on [priority].
  void killChild({required Object id, int priority = Isolate.beforeNextEvent}) {
    _isolates.remove(id)?.kill(priority: priority);
    _sendPorts.remove(id);
  }

  /// Sends an object to the child with the given ID.
  void sendToChild({required S data, required Object id}) {
    final port = _sendPorts[id];
    if (port == null) throw ArgumentError("No child isolate found with id=$id");
    port.send(data);
  }

  /// Spawns the given child and establishes two-way communication.
  ///
  /// This function instructs [Isolate.spawn] to call [IsolateChild.registerWithParent] which registers the child
  /// with the parent. After that, the child calls [IsolateChild.init], which you may override if you
  /// wish to run code on startup. Some use cases don't need this, however, and may defer work
  /// instead until the parent calls upon them.
  ///
  /// Note that the type arguments [R] and [S] are flipped -- that is, if the parent sends data of
  /// of type [S], then the child must receive type [S], and vice versa.
  Future<Isolate> spawn(IsolateChild<R, S> child) async {
    if (_receiver == null) {
      throw StateError(
        "You must call IsolateParent.init() before calling spawn()",
      );
    } else if (_isolates.containsKey(child.id)) {
      throw ArgumentError("An isolate with ID [${child.id}] already exists");
    }

    final completer = Completer<void>();
    _completers[child.id] = completer;
    final isolate = await Isolate.spawn(
      child.registerWithParent,
      _receiver!.sendPort,
    );
    _isolates[child.id] = isolate;
    // wait for the child to send a [ChildIsolateRegistration]
    await completer.future;
    return isolate;
  }
}
