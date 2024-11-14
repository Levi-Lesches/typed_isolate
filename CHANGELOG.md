## 6.0.0
- **Breaking change**: Made `IsolateChild.onSpawn()` a `Future<void>`. Messages will not be handled and `onData` will not be called until after `onSpawn()` finishes. If you need to run a lot of code on spawn, split it into two parts where one must be run before handling new messages, and one that can be handled later, then use `await` for the first and `unawaited` for the second.

## 5.0.0
- Added `IsolateChild.stream`
- Added `IsolateParent.stream`
- Added `IsolateParent.hasChild()`
- Added `IsolateParent.killChild()`
- Updated docs, example, and README
- Fixed bug where `IsolateParent.dispose()` was not using the given `priority` parameter.

#### Breaking changes
- `IsolateParent` is no longer meant to be subclassed. Simply create one and call `init` on it as usual.
- `IsolateParent.send()` has been renamed to `sendToChild()`, and `IsolateChild.send()` has bene renamed to `sendToParent()`
- Removed `IsolateParent.onData`. Subscribe to `IsolateParent.stream` instead
- Removed `IsolateChild.init`. Override `IsolateChild.onSpawn` instead.

## 4.0.0

- **Breaking**: Merged `IsolateParent.stopListening()` and `IsolateParent.killAll()` into `IsolateParent.dispose()`
- **New warning**: Annotated `IsolateParent.init()` with `@mustCallSuper`

## 3.0.0

- Renamed `IsolateParent.stop()` to `IsolateParent.stopListening()` and added `IsolateParent.killAll()`

## 2.0.1

- Minor formatting fixes

## 2.0.0

Changed signature of `IsolateParent.onData` and `IsolateParent.send` to contain the `IsolateChild.id`

## 1.0.1

- Updated example with correct imports and lints.

## 1.0.0

- Initial version.
