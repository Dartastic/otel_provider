# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0-beta.1] - 2026-05-16

### Added

- `OTelChangeNotifierMixin` — `mixin on ChangeNotifier` that emits
  one short span on every `notifyListeners()` (gated by
  `hasListeners`) and on `dispose()`. Each span carries
  `notifier.name` (the runtime type) and `notifier.event`.
- `ValueNotifier<T>` integration: classes that mix the OTel mixin
  in AND override `otelRecordValues => true` also get
  `notifier.value` (clipped via `otelValueMaxLength`) and
  `notifier.value.type` on each `notify` span. Off by default
  because notifier values often carry user data.
- `ProviderSemantics` — typed attribute-key enum implementing
  `OTelSemantic`, package-local because OTel has no upstream
  convention for ChangeNotifier yet.
- Tracer is resolved lazily on first emit and cached, so the
  mixin can be applied to a class regardless of when
  `OTel.initialize()` runs.
- Works with both `package:provider` consumers and any other
  ChangeNotifier-using code (Flutter foundation provides the
  notifier mechanism; `provider` is just the most common
  consumer).
- 5 widget tests cover: `notifyListeners` with a listener emits
  notify span, `notifyListeners` with no listeners short-circuits,
  `dispose` emits disposed span, `ValueNotifier` with
  `recordValues: true` captures clipped value + type,
  `ValueNotifier` without `recordValues` records neither.
- Flutter example app with `ChangeNotifierProvider` +
  `ValueNotifier`-based message model; `flutter run -d chrome` and
  click around to see the timeline in Grafana.
- Uses `DOTel.initialize` from the start to demonstrate the
  Pro SDK's one-character switch.
