import "ports.dart";

/// A message that is sent from a child isolate to its parent.
///
/// [S] represents the type of data that is being sent, and [R] represents the type of data the
/// sender is expecting receive back. So this should be used by an [IsolateChild<S, R>].
///
/// This class is always sent between isolates so that the child isolate can choose to send either
/// its data or its [TypedSendPort], and the parent isolate can use the data or use the port.
sealed class ChildIsolatePayload<S, R> {
  /// The ID of the child isolate.
  final Object id;

  ChildIsolatePayload({required this.id});
}

/// Represents a child isolate registering itself with its parent.
class ChildIsolateRegistration<S, R> extends ChildIsolatePayload<S, R> {
  /// The type-safe port the parent should use to communicate with the child.
  final TypedSendPort<R> port;

  /// Represents a child isolate registering itself with its parent.
  ChildIsolateRegistration({required this.port, required super.id});
}

/// Represents a child isolate sending data to its parent.
class ChildIsolateData<S, R> extends ChildIsolatePayload<S, R> {
  /// The data being sent.
  final S data;

  /// Represents a child isolate sending data to its parent.
  ChildIsolateData({required this.data, required super.id});
}
