import "dart:async";
import "dart:isolate";

import "ports.dart";
import "payload.dart";
import "child.dart";

/// A parent isolate that can spawn children isolates.
///
/// This class runs some initialization logic in [init], which may spawn some children isolates
/// using [spawn]. Each child isolate should be a subclass of [IsolateChild], and must override
/// its ID to be unique from every other child that this parent will spawn. It is an error for
/// two [IsolateChild]s spawned by [spawn] to have the same ID, as it will confuse the parent.
///
/// Two-way communication is implemented by calling [send] to send some data to the child with
/// the given ID, and by overriding [onData] to be notified when a child sends some data back.
/// Be sure to call [close] when finished with this parent to stop listening to child messages.
///
/// This class has two type arguments, [S] for the type being sent and [R] for the type being
/// received. To keep the logic straightforward, this parent must send the same type [S] to all
/// its children, and each child can only send messages of type [R]. If different data types
/// are desired, try making a more complex class to contain the fields you need, or make a new
/// parent to spawn children of different types.
///
/// Note that [S] and [R] will be flipped with respect to this class's children: if you send
/// integers and expect strings, then each child must expect integers and send strings.
abstract class IsolateParent<S, R> {
  late final _receiver = TypedReceivePort<IsolatePayload<R, S>>(ReceivePort());
  late final StreamSubscription<IsolatePayload<R, S>> _subscription;
  final Map<Object, TypedSendPort<S>> _sendPorts = {};

  /// Starts listening to [IsolatePayload]s sent by this isolate's children.
  IsolateParent() {
    _subscription = _receiver.listen((payload) {
      if (payload.port != null) {
        if (_sendPorts.containsKey(payload.id)) {
          throw StateError(
              "Trying to register two child isolates with the same ID: ${payload.id}");
        }
        _sendPorts[payload.id] = payload.port!;
      }
      if (payload.data != null) onData(payload.data as R, payload.id);
    });
  }

  /// Starts running this isolate's "main" code. Usually used to spawn children.
  void init();

  /// Sends the object to the child with the given ID.
  void send({required S data, required Object id}) {
    final port = _sendPorts[id];
    if (port == null) throw ArgumentError("No child isolate found with id=$id");
    port.send(data);
  }

  /// A callback that runs when data is sent by a child.
  void onData(R data, Object id);

  /// Stops listening to messages from this isolate's children.
  void close() {
    _subscription.cancel();
    _receiver.close();
  }

  /// Spawns the child and calls [IsolateChild.init] to establish two-way communication.
  Future<Isolate> spawn(IsolateChild<R, S> child) =>
      Isolate.spawn<TypedSendPort<IsolatePayload<R, S>>>(
          child.init, _receiver.sendPort);
}
