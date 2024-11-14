import "dart:isolate";

import "package:meta/meta.dart";

import "payload.dart";
import "ports.dart";

/// A child isolate that is spawned by another isolate
///
/// A subclass of this should override [id] to uniquely identify itself among other children.
///
/// - Optionally override [onSpawn] to run code when the child isolate is spawned
/// - Override [onData] to handle data sent by the parent isolate
/// - Use [sendToParent] to send data to the parent isolate
///
/// The type arguments [S] and [R] represent the types of data that will be Sent and Received,
/// from the child isolate's perspective. That is, if the parent sends integers and expects Strings,
/// then [S] on the child should be [String] and [R] should be [int] -- the opposite of the parent.
abstract class IsolateChild<S, R> {
  /// A unique identifier for this child to identify itself to the parent.
  final Object id;

  /// The type-safe [ReceivePort] that will receive messages of type [R] from the parent.
  late final TypedReceivePort<R> _receiver;

  /// The type-safe [SendPort] to send meessages of type [S] to the parent.
  ///
  /// This port is also used by [registerWithParent] to send [_receiver]'s send port back to the
  /// parent to establish two-way communications. Using a [ChildIsolatePayload] allows the child
  /// to send either the send port or data.
  late final TypedSendPort<ChildIsolatePayload<S, R>> _sender;

  /// Creates an isolate child with the given ID.
  IsolateChild({required this.id});

  /// Runs when the child isolate is spawned, after [registerWithParent] is called.
  void onSpawn() {}

  /// A callback to run when new data is received from the parent.
  void onData(R data);

  /// Sends data to the parent isolate.
  void sendToParent(S obj) {
    final payload = ChildIsolateData<S, R>(id: id, data: obj);
    _sender.send(payload);
  }

  /// Registers this child with its parent.
  ///
  /// This function is critical for establishing commmunication and should not be modified. If you
  /// need to run code when the isolate is spawned, prefer to override [onSpawn] instead. If you must
  /// override this, be sure to call `super.registerWithParent()` first.
  @mustCallSuper
  void registerWithParent(TypedSendPort<ChildIsolatePayload<S, R>> port) {
    _receiver = TypedReceivePort<R>(ReceivePort());
    _receiver.stream.listen(onData);
    _sender = port;
    _sender.send(
      ChildIsolateRegistration<S, R>(
        id: id,
        port: _receiver.sendPort,
      ),
    );
    onSpawn();
  }

  /// A broadcast stream of all messages from the parent.
  Stream<R> get stream => _receiver.stream;
}
