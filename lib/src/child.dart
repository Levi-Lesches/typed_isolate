import "dart:isolate";

import "payload.dart";
import "ports.dart";

/// A child isolate that is spawned by another isolate.
///
/// A subclass of this should override [id] to uniquely identify itself among other children.
/// Override [onData] to handle data sent by the parent isolate, and call [send] to send data
/// back to the parent. Override [run] to run code when the child isolate is spawned.
///
/// The type arguments [S] and [R] represent the types of data that will be Sent and Received,
/// from the child isolate's perspective. That is, if the parent sends integers and expects Strings,
/// then [S] on the child should be [String] and [R] should be [int] -- the opposite of the parent.
abstract class IsolateChild<S, R> {
  /// The ID of this child. Used to identify it to the parent.
  final Object id;

  /// The type-safe [ReceivePort] that will receive messages of type [R] from the parent.
  ///
  /// This field is `late final` so it can be created in [init] as opposed to when the isolate is
  /// created. That way, we don't try to send it across isolates (which is forbidden).
  late final TypedReceivePort<R> receiver;

  /// The type-safe [SendPort] to send meessages of type [S] to the parent.
  ///
  /// This port is also used by [init] to send [receiver]'s [TypedSendPort<R>] back to the parent
  /// to establish two-way communications. Because this port needs to send either another port
  /// or an actual message of type [S], it sends an [IsolatePayload<S, R>] to be safe.
  late final TypedSendPort<IsolatePayload<S, R>> _sender;

  /// Creates an isolate child with the given ID.
  IsolateChild({required this.id});

  /// Runs when the child isolate is spawned, after [init] is called.
  void run();

  /// A callback to run when new data is received from the parent.
  void onData(R data);

  /// Sends data to the parent.
  void send(S obj) {
    final payload = IsolatePayload<S, R>(id: id, data: obj);
    _sender.send(payload);
  }

  /// Saves the given [TypedSendPort], and creates a [TypedReceivePort] to send to the parent.
  void init(TypedSendPort<IsolatePayload<S, R>> port) {
    receiver = TypedReceivePort<R>(ReceivePort());
    receiver.listen(onData);
    _sender = port;
    final payload = IsolatePayload<S, R>(id: id, port: receiver.sendPort);
    _sender.send(payload);
    run();
  }

  /// A broadcast stream of all messages from the parent.
  Stream<R> get stream => receiver.asBroadcastStream();
}
