import "dart:isolate";
import "dart:async";

/// A type-safe [SendPort] that only allows you to send [T] objects.
extension type TypedSendPort<T>(SendPort _port) {
  /// Sends a [T] object.
  void send(T obj) => _port.send(obj);
}

/// A type-safe [ReceivePort] that only receives [T] objects.
extension type TypedReceivePort<T>(ReceivePort _port) {
  /// A broadcast stream with all incoming data.
  Stream<T> get stream => _port.asBroadcastStream().cast();

  /// Get the type-safe [SendPort] for this [ReceivePort].
  TypedSendPort<T> get sendPort => TypedSendPort<T>(_port.sendPort);

  /// Closes the underlying port by calling [ReceivePort.close].
  void close() => _port.close();
}
