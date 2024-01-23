// ignore_for_file: avoid_print

import "package:typed_isolate/typed_isolate.dart";

class NumberSender extends IsolateParent<int, String> {
  @override
  Future<void> init() async {
    print("Opening parent...");
    print("Sending: 1");
    send(data: 1, id: "braces");
    send(data: 1, id: "brackets");
    await Future<void>.delayed(const Duration(seconds: 1));

    print("Sending: 2");
    send(data: 2, id: "brackets");
    send(data: 2, id: "braces");
    await Future<void>.delayed(const Duration(seconds: 1));

    print("Sending: 3");
    send(data: 3, id: "braces");
    send(data: 3, id: "brackets");
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  @override
  void onData(String str, Object id) => print("Got: $str");
}

class NumberConverter extends IsolateChild<String, int> {
  NumberConverter() : super(id: "brackets");

  @override
  void run() => print("Opening child...");

  @override
  void onData(int data) => send("[$data]");
}

class NumberConverter2 extends IsolateChild<String, int> {
  NumberConverter2() : super(id: "braces");

  @override
  void run() => print("Opening child...");

  @override
  void onData(int data) => send("{$data}");
}

void main() async {
  final parent = NumberSender();
  await parent.spawn(NumberConverter());
  await parent.spawn(NumberConverter2());
  await Future<void>.delayed(const Duration(seconds: 1));
  await parent.init();
  parent.stopListening();
  parent.killAll();
}
