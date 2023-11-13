import "ports.dart";

/// A message that is sent between isolates.
///
/// [S] represents the type of data that is being sent, and [R] represents the type of data the
/// sender is expecting receive back. So this should be used by an [IsolateChild<S, R>].
///
/// This class is always sent between isolates so that the child isolate can choose to send either
/// its data or its [TypedSendPort], and the parent isolate can use the data or use the port.
class IsolatePayload<S, R> {
  /// The ID of the child isolate.
  final Object id;

  /// The port to send messages back to, if any.
  final TypedSendPort<R>? port;

  /// The data to send, if any.
  final S? data;

  /// Creates a message that can contain either data or a [TypedSendPort].
  const IsolatePayload({required this.id, this.port, this.data});
}
