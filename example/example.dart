// ignore_for_file: avoid_print

import "package:typed_isolate/typed_isolate.dart";

class NumberSender {
  final parent = IsolateParent<int, String>();

  Future<void> run() async {
    parent.init();
    parent.stream.listen(onData);
    await parent.spawn(NumberConverter());
    await parent.spawn(NumberConverter2());
    print("Opening parent...");
    print("Sending: 1");
    parent.sendToChild(data: 1, id: "braces");
    parent.sendToChild(data: 1, id: "brackets");
    await Future<void>.delayed(const Duration(seconds: 1));

    print("Sending: 2");
    parent.sendToChild(data: 2, id: "brackets");
    parent.sendToChild(data: 2, id: "braces");
    await Future<void>.delayed(const Duration(seconds: 1));

    print("Sending: 3");
    parent.sendToChild(data: 3, id: "braces");
    parent.sendToChild(data: 3, id: "brackets");
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  void dispose() => parent.dispose();

  void onData(String str) => print("Got: $str");
}

class NumberConverter extends IsolateChild<String, int> {
  NumberConverter() : super(id: "brackets");

  @override
  void init() => print("Opening child $id...");

  @override
  void onData(int data) => sendToParent("[$data]");
}

class NumberConverter2 extends IsolateChild<String, int> {
  NumberConverter2() : super(id: "braces");

  @override
  void init() => print("Opening child $id...");

  @override
  void onData(int data) => sendToParent("{$data}");
}

void main() async {
  final parent = NumberSender();
  await parent.run();
  parent.dispose();
}
