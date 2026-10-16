<!-- dartastic-header:start -->
# OpenTelemetry instrumentation for `provider`

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![OpenTelemetry Specification](https://img.shields.io/badge/OpenTelemetry-Specification-blueviolet)](https://opentelemetry.io/docs/specs/otel/)

`otel_provider` is an [OpenTelemetry](https://opentelemetry.io/) instrumentation for `provider` that
easily adds standard observability to applications that use `provider`.  This package depends on 
[dartastic_opentelemetry_api](https://pub.dev/packages/dartastic_opentelemetry_api).

This package can be used with any OTel backend because it's compliant with the OpenTelemetry Specification.

This package supports Android, iOS, Linux, macOS, Web and Windows, for versions of `provider` that support those platforms. It is WASM-ready.

This Apache-2.0 package is professionally maintained and supported with 💙 by Michael Bushe,
Dart and Flutter Maintainer at OpenTelemetry and the creator of [dartastic_opentelemetry](https://pub.dev/packages/dartastic_opentelemetry)
and [dartastic_opentelemetry_api](https://pub.dev/packages/dartastic_opentelemetry_api). This package is professionally supported by
[Dartastic.io](https://dartastic.io).

---
## Dartastic.io: AI Code Healing and Real User Monitoring for Flutter

**See what your users experience. Find problems with Flutter apps in production. Fix them with AI.**

[Dartastic.io](https://dartastic.io) brings AI code healing, real user monitoring, and OpenTelemetry observability together in one platform built for Dart and Flutter. (Patents pending)

![Dartastic AI answering "Why did crashes jump after the last release?" over a Flutter App Health dashboard](https://dartastic.io/img/pub-dev/HomePageCrashesQuestion.png)

### Dartastic AI — From Production Problems to Code Fixes

Dartastic AI analyzes production telemetry alongside your application source code to diagnose problems and propose fixes.

- **Investigate production issues** using crashes, errors, traces, metrics, and real user telemetry.
- **Find the offending code** by connecting observed problems with your application's source in Dartastic Pub or your source code repos.
- **Generate code patches** that address the underlying problems.
- **Create actionable issues** in your issue tracker, complete with findings and the proposed code patch.

### Dartastic RUM — See What Your Users See

Understand how people actually experience your Flutter application.

- **Replay user sessions** in the Dartastic Observatory session player.
- **Choose your replay fidelity**, from privacy-preserving widget outlines to pixel-level reproductions of the user experience.
- **Investigate real user problems** using session replay and production observability data.

![Dartastic RUM Session Replay](https://dartastic.io/img/pub-dev/session-replay.png)

### Dartastic Observatory — Observability Built for Flutter

A complete observability backend where Flutter and Dart are first-class citizens.

- **Flutter-specific dashboards** for application performance, health, and reliability.
- **Alerts and notifications** through email, Slack, and PagerDuty.
- **Dartastic Cloud Observatory** — Start with a 30-day free trial on isolated, shared infrastructure, as low as $39/mo.
- **Dartastic Hosted Observatory** — Run the observability stack in a private managed environment, sized from Mini to Enterprise XL.
- **Dartastic Self-Hosted Observatory** — The whole platform inside your own network. Your keys, your cluster, with nothing leaving your perimeter.

### Dartastic Native OTel Runtime — Native OpenTelemetry Performance

Collect production telemetry without burdening Flutter's main isolate.

- **Native OpenTelemetry runtime** that moves telemetry processing off the main isolate.
- **Native crash reporting** for problems that Dart can't catch.
- **Widget performance diagnostics** to identify janky widgets.
- **On-device PII filtering** before sensitive data leaves your application.
- **Source-level error diagnostics** powered by the Dartastic Symbolizer API.
- **Platform-native metrics** for iOS, Android, and Linux, including iOS MetricKit and Android Vitals.
- **OpenTelemetry compatibility** — Send telemetry to Dartastic Observatory or any OpenTelemetry platform.

### Dartastic Labs — OpenTelemetry Integrations

Instrument more of your application without writing everything yourself.

- **650+ open-source integrations** for Dart and Flutter libraries and services, including Dio, Shelf, Logger, Anthropic, AWS, Azure, and Stripe. Look for otel_* on pub.dev.

### More Dartastic Tools

**[Dartastic Pub](https://dartastic.io/pub)**

A private Dart package registry for sharing packages and plugins with your team, partners, and customers.

**[Dartastic Symbolizer](https://dartastic.io/symbolizer)**

Turn production errors into lines of source code through a web API, while keeping your source code artifacts private.

### Professional Support and Training

Dartastic.io offers commercial support for the open-source `dartastic_opentelemetry` and `dartastic_opentelemetry_api` packages and the complete Dartastic product suite.

- **Professional support** with available around-the-clock coverage and response times under four hours on qualifying plans.
- **OpenTelemetry training** for teams instrumenting Dart, Flutter, mobile, and web applications.

### Open Standards. No Mandatory Backend.

The Dartastic OpenTelemetry API and SDK are open source and standards-based. You can use them independently of Dartastic's commercial services and send telemetry to any compatible OpenTelemetry backend.

Dartastic's commercial products add native performance, advanced diagnostics, session replay, AI-assisted remediation, and managed observability services.

**[Explore Dartastic.io](https://dartastic.io)**

---
<!-- dartastic-header:end -->

OpenTelemetry instrumentation for [`package:provider`](https://pub.dev/packages/provider)
and any code using `ChangeNotifier`. Built on the
[Dartastic OpenTelemetry SDK](https://pub.dev/packages/dartastic_opentelemetry).

Mix in `OTelChangeNotifierMixin` on your notifier and every
`notifyListeners()` + `dispose()` produces a short span — your
state-mutation timeline in your trace viewer, automatically.

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
from polluting your traces with noise.

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
