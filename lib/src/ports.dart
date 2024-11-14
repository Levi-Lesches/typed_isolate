import "dart:isolate";
import "dart:async";

/// A type-safe [SendPort] that only allows you to send [T] objects.
class TypedSendPort<T> {
  final SendPort _port;

  /// Wraps a native [SendPort].
  TypedSendPort(this._port);

  /// Sends a [T] object.
  void send(T obj) => _port.send(obj);
}

/// A type-safe [ReceivePort] that only receives [T] objects.
class TypedReceivePort<T> extends StreamView<T> {
  final ReceivePort _port;

  /// Wraps a native [ReceivePort] and casts it to [T].
  TypedReceivePort(this._port) : super(_port.asBroadcastStream().cast<T>());

  /// Get the [TypedSendPort] for this [ReceivePort].
  TypedSendPort<T> get sendPort => TypedSendPort<T>(_port.sendPort);

  /// Closes the underlying port by calling [ReceivePort.close].
  void close() => _port.close();
}
