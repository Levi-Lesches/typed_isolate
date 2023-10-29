import "dart:isolate";
import "dart:async";

class SendPort2<T> {
  final SendPort _port;
  SendPort2(this._port);

  void send(T obj) => _port.send(obj);
}

class ReceivePort2<T> extends StreamView<T> {
  final ReceivePort port;
  ReceivePort2(this.port) : super(port.cast<T>());

  SendPort2<T> get sendPort => SendPort2<T>(port.sendPort);
}
