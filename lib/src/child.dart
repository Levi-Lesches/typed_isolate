import "dart:isolate";

import "payload.dart";
import "ports.dart";

abstract class IsolateChild<S, R> {
  final Object id;
  late final ReceivePort2<R> receiver;  // needs to be late to be created in the child isolate!
  late final SendPort2<IsolatePayload<S, R>> _sender;

  IsolateChild({required this.id});

  void run();
  void onData(R data);
  void send(S obj) {
    final payload = IsolatePayload<S, R>(id: id, data: obj);
    _sender.send(payload);
  }
  void init(SendPort2<IsolatePayload<S, R>> port) {
    receiver = ReceivePort2<R>(ReceivePort());
    receiver.listen(onData);
    _sender = port;
    final payload = IsolatePayload<S, R>(id: id, port: receiver.sendPort);
    _sender.send(payload);
    run();
  }
}
