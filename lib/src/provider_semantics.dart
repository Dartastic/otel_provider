// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

/// Typed attribute keys for `ChangeNotifier` / `package:provider`
/// instrumentation.
///
/// No upstream OTel semantic convention exists for ChangeNotifier
/// notifications; the `notifier.*` namespace is package-local pending
/// a proposal to the OTel client-side SIG. Stable across the 0.x line
/// — renaming a key is a breaking change.
enum ProviderSemantics implements OTelSemantic {
  /// The notifier's `runtimeType` string (e.g., `CartModel`,
  /// `AuthState`). The natural identity for "which notifier emitted".
  notifierName('notifier.name'),

  /// Which hook fired — `notify` or `disposed`.
  event('notifier.event'),

  /// For `ValueNotifier<T>` notifications when `recordValues: true`,
  /// `value.toString()` clipped to the configured max length.
  value('notifier.value'),

  /// For `ValueNotifier<T>` notifications when `recordValues: true`,
  /// `T.toString()` (the value's runtime type).
  valueType('notifier.value.type');

  const ProviderSemantics(this.key);

  @override
  final String key;

  @override
  String toString() => key;
}
