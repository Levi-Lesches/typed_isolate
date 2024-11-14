# typed_isolate

Easier and type-safe isolate usage with support for parent and child isolates and easy 2-way communication between them.

## Features
- Declare a parent isolate that handles incoming data and can send messages to children isolates
- Declare a child isolate or isolates to handle requests from and send data to the main isolate
- Easily spawn children isolates from the parent isolate
- Natural support for long-living isolates
- Full type safety thanks to type arguments everywhere!

## Usage

To start, create an `IsolateParent` and call `init()`. After calling `spawn()` to create a child, use `sendToChild` and subscribe to its `stream`:

```dart
void main() async {
  // Sends ints, receives strings
  final parent = IsolateParent<int, String>();
  parent.init();
  parent.stream.listen(print);
  await parent.spawn(MyChildIsolate(id: "my-child-id"));
  parent.sendToChild(id: "my-child-id", data: 1);
}
```

To create a child, subclass `IsolateChild` and provide an `id` and an `onData` handler for handling messages from the parent isolate. Use `sendToParent` to send data back to the parent. If you'd like to run code when the child spawns, override `onSpawn`.

Here's an example of a child isolate that receives integers and wraps them in square brackets.

```dart
// Sends strings, receives ints
class NumberConverter extends IsolateChild<String, int> {
  NumberConverter() : super(id: "brackets");

  @override
  void onSpawn() => print("Opening child $id...");

  @override
  void onData(int data) => sendToParent("[$data]");
}
```

For a fully integrated example, see the `Example` tab or `example/example.dart`.
