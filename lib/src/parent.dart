import "dart:async";
import "dart:isolate";

import "ports.dart";
import "payload.dart";
import "child.dart";

abstract class IsolateParent<S, R> {
  late final _receiver = ReceivePort2<IsolatePayload<R, S>>(ReceivePort());
  late final StreamSubscription<IsolatePayload<R, S>> _subscription;
  final Map<Object, SendPort2<S>> _sendPorts = {};

  IsolateParent() {
    _subscription = _receiver.listen((payload) {
      if (payload.port != null) _sendPorts[payload.id] = payload.port!;
      if (payload.data != null) onData(payload.data as R);
    });
  }
  
  void run();
  void onData(R data);

  void send(S obj, Object id) { _sendPorts[id]!.send(obj); }
  void close() {
    _subscription.cancel();
    _receiver.port.close();
  }

  Future<Isolate> spawn(IsolateChild<R, S> child) => 
    Isolate.spawn<SendPort2<IsolatePayload<R, S>>>(child.init, _receiver.sendPort);
}
