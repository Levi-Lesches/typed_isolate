import "ports.dart";

class IsolatePayload<S, R> {
  final SendPort2<R>? port;
  final S? data;
  final Object id;

  IsolatePayload({required this.id, this.port, this.data});
}
