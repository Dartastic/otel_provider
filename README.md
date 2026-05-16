# otel_provider

OpenTelemetry instrumentation for [`package:provider`](https://pub.dev/packages/provider)
and any code using `ChangeNotifier`. Built on the
[Dartastic OpenTelemetry SDK](https://pub.dev/packages/dartastic_opentelemetry).

Mix in `OTelChangeNotifierMixin` on your notifier and every
`notifyListeners()` + `dispose()` produces a short span — your
state-mutation timeline in Tempo, automatically.

```dart
class CartModel extends ChangeNotifier with OTelChangeNotifierMixin {
  final _items = <Item>[];
  void add(Item i) {
    _items.add(i);
    notifyListeners(); // span emitted here
  }
}
```

The notifier machinery lives in Flutter foundation, not in
`package:provider` itself, so this package works for **any**
`ChangeNotifier` — pure-Flutter code, GetX models that happen to be
ChangeNotifiers, custom solutions, all of them. The name is provider
because that's the most common consumer.

## Why mix in, not wrap?

A `ChangeNotifierProvider` wrapper widget can't see notifications —
the only way to hook them is from inside the notifier itself. The
mixin pattern is the cleanest version of that: minimal viral spread
through your code (one extra `with` clause), no behavior changes,
no API for downstream callers to learn.

## Span shape

| Hook | Span name | Status |
|---|---|---|
| `notifyListeners` (when `hasListeners`) | `notifier.notify:<runtimeType>` | unset |
| `dispose` | `notifier.disposed:<runtimeType>` | unset |

| Attribute | Source | When set |
|---|---|---|
| `notifier.name` | `runtimeType.toString()` | every span |
| `notifier.event` | `notify` / `disposed` | every span |
| `notifier.value` | `value.toString()` (clipped) | only on `ValueNotifier`-style classes with `otelRecordValues == true` |
| `notifier.value.type` | `value.runtimeType` | same conditions |

`notifyListeners` with no current listeners short-circuits — no span
is emitted. This matches `ChangeNotifier`'s own behavior (it doesn't
dispatch when nobody is listening), and prevents off-screen models
from polluting your Tempo view with noise.

## ValueNotifier support

When you mix the OTel mixin into a `ValueNotifier<T>`, you can
opt into recording the value itself by overriding `otelRecordValues`:

```dart
class _Search extends ValueNotifier<String> with OTelChangeNotifierMixin {
  _Search(super.initial);

  @override
  bool get otelRecordValues => true;

  @override
  int get otelValueMaxLength => 64;
}
```

Off by default because notifier values often carry user data.

## Caveats

- Resolves the tracer lazily on first emit, so it's safe to mix
  this in even before `OTel.initialize()` runs. The tracer is
  cached after first use.
- The `notifier.notify` span is emitted **before** `super.notifyListeners()`
  fires, so it appears before listeners are notified — the natural
  order for trace causality.
- `package:provider`'s `ChangeNotifierProvider` auto-disposes its
  notifier when the surrounding widget tree unmounts. The
  `dispose` span will fire then.

## License

Apache 2.0 — see `LICENSE`.
