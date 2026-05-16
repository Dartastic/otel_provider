// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otel_provider/otel_provider.dart';

class _MemorySpanExporter implements SpanExporter {
  final List<Span> spans = [];
  bool _shutdown = false;

  @override
  Future<void> export(List<Span> s) async {
    if (_shutdown) return;
    spans.addAll(s);
  }

  @override
  Future<void> forceFlush() async {}

  @override
  Future<void> shutdown() async {
    _shutdown = true;
  }
}

Map<String, Object> _attrs(Span span) =>
    {for (final a in span.attributes.toList()) a.key: a.value};

// --- Test fixtures ---

class _Counter extends ChangeNotifier with OTelChangeNotifierMixin {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}

/// ValueNotifier composed with the OTel mixin — exercises the
/// `recordValues` codepath.
class _StringValue extends ValueNotifier<String> with OTelChangeNotifierMixin {
  _StringValue(super.value);

  @override
  bool get otelRecordValues => true;

  @override
  int get otelValueMaxLength => 6;
}

void main() {
  group('OTelChangeNotifierMixin', () {
    late _MemorySpanExporter exporter;

    setUp(() async {
      await OTel.reset();
      exporter = _MemorySpanExporter();
      await OTel.initialize(
        serviceName: 'provider-otel-test',
        detectPlatformResources: false,
        spanProcessor: SimpleSpanProcessor(exporter),
      );
    });

    tearDown(() async {
      await OTel.shutdown();
      await OTel.reset();
    });

    test('notifyListeners with a listener emits a notify span', () {
      final c = _Counter();
      // ChangeNotifier suppresses dispatch when nobody is listening;
      // attach a listener so the spans fire.
      c.addListener(() {});
      c.increment();

      final notify = exporter.spans
          .firstWhere((s) => s.name == 'notifier.notify:_Counter');
      final attrs = _attrs(notify);
      expect(attrs['notifier.name'], equals('_Counter'));
      expect(attrs['notifier.event'], equals('notify'));
      // Value not recorded by default.
      expect(attrs.containsKey('notifier.value'), isFalse);
    });

    test('notifyListeners with no listeners produces no span', () {
      final c = _Counter();
      c.increment(); // no listener attached

      expect(
        exporter.spans.any((s) => s.name.startsWith('notifier.notify:')),
        isFalse,
        reason: 'hasListeners=false should short-circuit the span emit',
      );
    });

    test('dispose emits a disposed span', () {
      final c = _Counter();
      c.dispose();

      final disposed = exporter.spans.firstWhere(
        (s) => s.name == 'notifier.disposed:_Counter',
      );
      expect(_attrs(disposed)['notifier.event'], equals('disposed'));
    });

    test('ValueNotifier with otelRecordValues records the new value', () {
      final v = _StringValue('hello');
      v.addListener(() {});
      v.value = 'something longer than the cap'; // 29 chars

      final notify = exporter.spans.firstWhere(
        (s) => s.name == 'notifier.notify:_StringValue',
      );
      final attrs = _attrs(notify);
      expect(attrs['notifier.value.type'], equals('String'));
      // Clipped to otelValueMaxLength (6) + ellipsis.
      final value = attrs['notifier.value']! as String;
      expect(value, endsWith('…'));
      expect(value.length, equals(7));
    });

    test('ValueNotifier without recordValues records only type', () {
      // ValueNotifier mixed in WITHOUT overriding otelRecordValues:
      final v = _IntValuePlain(0);
      v.addListener(() {});
      v.value = 42;

      final notify = exporter.spans.firstWhere(
        (s) => s.name.startsWith('notifier.notify:'),
      );
      final attrs = _attrs(notify);
      // Default: no value attributes at all.
      expect(attrs.containsKey('notifier.value'), isFalse);
      expect(attrs.containsKey('notifier.value.type'), isFalse);
    });
  });
}

class _IntValuePlain extends ValueNotifier<int> with OTelChangeNotifierMixin {
  _IntValuePlain(super.value);
}
