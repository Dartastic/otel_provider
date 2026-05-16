// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter/foundation.dart';

import 'provider_semantics.dart';

/// Mixin on `ChangeNotifier` that emits one short OTel span every time
/// `notifyListeners()` fires, plus one on `dispose()`.
///
/// Designed for the `package:provider` ecosystem but works on any
/// `ChangeNotifier` (the `notifyListeners` machinery lives in Flutter
/// foundation, not in `package:provider` itself). Mix it into your
/// existing notifier classes — no class hierarchy changes needed
/// downstream.
///
/// ```dart
/// class CartModel extends ChangeNotifier with OTelChangeNotifierMixin {
///   final _items = <Item>[];
///   void add(Item i) {
///     _items.add(i);
///     notifyListeners(); // <- span emitted here
///   }
/// }
/// ```
///
/// Span shape per hook:
///
/// | Hook | Span name | Status |
/// |---|---|---|
/// | `notifyListeners` | `notifier.notify:<runtimeType>` | unset |
/// | `dispose` | `notifier.disposed:<runtimeType>` | unset |
///
/// Both spans carry `notifier.name` (the runtime type) and
/// `notifier.event` (`notify` / `disposed`).
///
/// For `ValueNotifier<T>` subclasses, set `recordValues = true`
/// at construction (override `otelRecordValues`) to capture the new
/// value's `toString()` and runtime type on each notify.
mixin OTelChangeNotifierMixin on ChangeNotifier {
  // Lazily resolved so OTel.initialize can run after mixin'd notifiers
  // are imported. Cached after first use because tracer lookup is
  // cheap but still does a map traversal.
  Tracer? _otelTracer;
  Tracer get _tracer => _otelTracer ??=
      OTel.tracerProvider().getTracer('otel_provider');

  /// When `true`, `notify` spans on `ValueNotifier<T>` include
  /// `notifier.value` (clipped to [otelValueMaxLength]) and
  /// `notifier.value.type` attributes. Defaults to `false` because
  /// notifier values often carry user data.
  ///
  /// Override in your class to opt in:
  ///
  /// ```dart
  /// class _Mine extends ValueNotifier<String> with OTelChangeNotifierMixin {
  ///   @override
  ///   bool get otelRecordValues => true;
  /// }
  /// ```
  bool get otelRecordValues => false;

  /// Cap on the length of `notifier.value` when [otelRecordValues] is
  /// `true`. Defaults to 256.
  int get otelValueMaxLength => 256;

  @override
  void notifyListeners() {
    if (hasListeners) {
      _emit(event: 'notify', includeValue: otelRecordValues);
    }
    super.notifyListeners();
  }

  @override
  void dispose() {
    _emit(event: 'disposed');
    super.dispose();
  }

  void _emit({required String event, bool includeValue = false}) {
    final name = runtimeType.toString();
    final attrs = <String, Object>{
      ProviderSemantics.notifierName.key: name,
      ProviderSemantics.event.key: event,
    };

    if (includeValue) {
      // Recover the typed `value` accessor when the notifier is a
      // ValueListenable (ValueNotifier subclasses, etc.). The
      // pattern-match destructure side-steps `this`-promotion limits.
      if (this case final ValueListenable<Object?> vl when vl.value != null) {
        final v = vl.value!;
        attrs[ProviderSemantics.valueType.key] = v.runtimeType.toString();
        attrs[ProviderSemantics.value.key] = _clip(v.toString());
      }
    }

    final span = _tracer.startSpan(
      'notifier.$event:$name',
      attributes: OTel.attributesFromMap(attrs),
    );
    span.end();
  }

  String _clip(String s) {
    if (s.length <= otelValueMaxLength) return s;
    return '${s.substring(0, otelValueMaxLength)}…';
  }
}
