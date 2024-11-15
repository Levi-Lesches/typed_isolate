// ignore_for_file: avoid_print

import "package:typed_isolate/typed_isolate.dart";

class NumberConverter extends IsolateChild<String, int> {
  NumberConverter() : super(id: "brackets");

  @override
  Future<void> onSpawn() async {}

  @override
  void onData(int data) => sendToParent("[$data]");
}

class NumberConverter2 extends IsolateChild<String, int> {
  NumberConverter2() : super(id: "braces");

  @override
  Future<void> onSpawn() async {
    // [onData] will not be called until this finishes
    sendToParent("Opening child $id in 3 seconds...");
    await Future<void>.delayed(const Duration(seconds: 3));
  }

  @override
  void onData(int data) => sendToParent("{$data}");
}

void onData(String str) => print("Got: $str");

void main() async {
  print("Opening parent...");
  final parent = IsolateParent<int, String>();
  parent.init();
  parent.stream.listen(onData);
  await parent.spawn(NumberConverter());
  await parent.spawn(NumberConverter2());

  for (var i = 1; i < 4; i++) {
    parent.sendToChild(data: i, id: "braces");
    parent.sendToChild(data: i, id: "brackets");
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  await parent.dispose();
}
