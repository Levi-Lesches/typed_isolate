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
