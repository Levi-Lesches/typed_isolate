# typed_isolate

Easier and type-safe isolate usage with support for parent and child isolates and easy 2-way communication between them.

## Features
- Declare a parent isolate that handles incoming data and can send messages to children isolates
- Declare a child isolate or isolates to handle requests from and send data to the main isolate
- Easily spawn children isolates from the parent isolate
- Natural support for long-living isolates
- Full type safety thanks to type arguments everywhere!

## Usage

Here's an example of a child isolate that receives integers and wraps them in square brackets. 

```dart
class NumberConverter extends IsolateChild<String, int> {
  NumberConverter() : super(id: "brackets");
  
  @override
  void run() => print("Opening child...");

  @override
  void onData(int data) => send("[$data]");
}
```
