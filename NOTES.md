# Cart Four Ways Notes

## Part 1: inline questions

### Why is `CartLine` immutable with a `copyWith` instead of a mutable `qty` field?
`CartLine` is immutable because state updates are represented as new values instead of in-place mutations. That makes equality checks reliable, prevents accidental shared mutations, and lets the same logic be reused by `setState`, Riverpod, Cubit and Bloc without subtle bugs.

### Which of the four styles would still "work" with mutation, and why is that a trap?
`setState` can still appear to work if you mutate a list in place, because Flutter will rebuild when `setState` is called. The trap is that the state object still changes without producing a new value, so equality-based optimizations and listener subscriptions stop working reliably. Riverpod, Cubit and Bloc all rely on value changes or equality to decide when to notify observers; mutable state breaks that contract and creates hard-to-debug stale UI bugs.

### Why does `CartBody` take callbacks instead of importing a provider or a bloc directly?
`CartBody` is intentionally dumb UI. It only receives data and callback functions, so it can be shared across all four implementations without depending on any specific state-management library. This keeps the UI reusable, testable, and decoupled from the wiring layer.

## Part 2–5: checkpoint answers

### 1) Where the state lives and when it dies
- `setState`: lives on the widget `State` object; dies when the page is removed.
- Riverpod: lives in the `ProviderContainer` owned by the `ProviderScope`; it survives when the page is popped unless explicitly disposed.
- Cubit: lives in the `Cubit` instance created by `BlocProvider`; dies when the provider is disposed.
- Bloc: lives in the `Bloc` instance created by `BlocProvider`; dies when the provider is disposed.

### 2) Single public mutation API
- Riverpod `Notifier`: `state = ...` via the notifier methods (`add`, `remove`, etc.).
- Cubit: `emit(...)`.
- Bloc: `add(Event)`; the event is handled by a reducer-style handler.
- `setState` has no formal mutation API; it directly reassigns state inside the widget.

### 3) `ref.watch`/`ref.read`/`ref.listen` vs `BlocBuilder`/`context.read`/`BlocListener`
- `ref.watch` subscribes a widget to a provider and rebuilds it when the value changes.
- `ref.read` looks up a provider once without subscribing.
- `ref.listen` runs side effects when a provider changes.
- `BlocBuilder` subscribes a widget to a bloc/cubit and rebuilds on new state.
- `context.read` reads the bloc/cubit without rebuilding.
- `BlocListener` runs side effects (snackbars, banners, navigation) without rebuilding.
- `setState` is the direct widget-local rebuild trigger.

### 4) Why `==` matters for state deduplication
Riverpod, Cubit and Bloc skip notifications when the new state is equal to the old one. To make that work, `CartState` must override `==` and `hashCode` and use immutable data. Then the framework can detect no real change and avoid unnecessary rebuilds.

### 5) Guards after async checkout
- `setState`: `if (!mounted) return;` before mutating state after an awaited async call.
- Riverpod: no guard is needed because the provider stays alive; the notifier is not bound to a widget lifecycle.
- Cubit: `if (isClosed) return;` or avoid emitting after close to prevent state updates after disposal.
- Bloc: `if (isClosed) return;` / `if (emit.isDone) return;` before emitting after the async call.

## Comparison table

| Style | T1–T5 lines of code | Test code | Files | Strength | Weakness |
| --- | --- | --- | --- | --- | --- |
| `setState` | Low | Low | 2–3 | Simplest mental model | Prop drilling and no centralized state |
| Riverpod | Medium | Low–Medium | 3–4 | Excellent caching and selective rebuilds | More provider setup boilerplate |
| Cubit | Medium | Medium | 3–4 | Minimal API with clear state transitions | Less traceability than Bloc |
| Bloc | High | High | 4–6 | Event traceability and testability | More boilerplate |

## Why storing `total` would be a bug
`total` is derived from `lines`, `coupon`, and pricing rules. If you store it as a field, it can drift out of sync with the cart contents or coupon changes. The safe pattern is to compute it from current state every time using getters.

## Duplicate-tap checkout
The checkout event is guarded with `droppable()` so a second `CartCheckoutRequested` while the first request is still running is ignored. This prevents double submissions without extra UI logic.
