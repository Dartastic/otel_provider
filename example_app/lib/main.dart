// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

/// Runnable Flutter demo of `otel_provider` against a local LGTM stack.
///
/// Run the stack:
///   docker compose -f ../../../tool/lgtm/docker-compose.yml up -d
///
/// Then run this app on any Flutter device (web is easiest):
///   flutter run -d chrome
///
/// Click the buttons in the UI. Open Grafana (http://localhost:3000)
/// → Explore → Tempo, search for service `provider-otel-example-app`
/// to see one trace per `notifyListeners()` and `dispose()`.
library;

import 'dart:io' show Platform;

// Example apps use the Pro SDK to demonstrate the one-character
// switch (OTel.initialize -> DOTel.initialize). The package source
// still imports the OSS SDK directly so non-Pro users can use it.
import 'package:dartastic_opentelemetry_pro/dartastic_opentelemetry_pro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:otel_provider/otel_provider.dart';
import 'package:provider/provider.dart';

const _serviceName = 'provider-otel-example-app';
const _defaultEndpoint = 'http://localhost:4318';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final endpoint = _readEndpoint();

  await DOTel.initialize(
    serviceName: _serviceName,
    serviceVersion: '0.0.1',
    endpoint: endpoint,
  );

  runApp(const _DemoApp());
}

String _readEndpoint() {
  if (kIsWeb) return _defaultEndpoint;
  return Platform.environment['OTEL_EXPORTER_OTLP_ENDPOINT'] ??
      _defaultEndpoint;
}

/// A typical `package:provider` model — `ChangeNotifier` plus the
/// OTel mixin. The only change is `with OTelChangeNotifierMixin`.
class _Counter extends ChangeNotifier with OTelChangeNotifierMixin {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }

  void reset() {
    _count = 0;
    notifyListeners();
  }
}

/// A ValueNotifier-style model that opts into recording values.
class _Message extends ValueNotifier<String> with OTelChangeNotifierMixin {
  _Message(super.initial);

  @override
  bool get otelRecordValues => true;
}

class _DemoApp extends StatelessWidget {
  const _DemoApp();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => _Counter()),
        ChangeNotifierProvider(create: (_) => _Message('hello')),
      ],
      child: const MaterialApp(home: _HomeScreen()),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    final counter = context.watch<_Counter>();
    final message = context.watch<_Message>();

    return Scaffold(
      appBar: AppBar(title: const Text('provider_otel demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('count: ${counter.count}'),
            const SizedBox(height: 8),
            Text('message: ${message.value}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: counter.increment,
              child: const Text('increment counter'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: counter.reset,
              child: const Text('reset counter'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => message.value =
                  'updated at ${DateTime.now().toIso8601String()}',
              child: const Text('update message'),
            ),
          ],
        ),
      ),
    );
  }
}
