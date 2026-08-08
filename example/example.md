# otel_provider example

```dart
// example/lib/main.dart

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter/material.dart';
import 'package:otel_provider/otel_provider.dart';
import 'package:provider/provider.dart';

/// A typical `package:provider` model — `ChangeNotifier` plus the
/// OTel mixin. The only change is `with OTelChangeNotifierMixin`.
class CartModel extends ChangeNotifier with OTelChangeNotifierMixin {
  final List<String> _items = [];
  List<String> get items => List.unmodifiable(_items);

  void add(String item) {
    _items.add(item);
    // ✨ Span: `notifier.notify:CartModel`
    //
    //    Emitted right before listeners run, carrying
    //    `notifier.name: CartModel` and `notifier.event: notify`.
    notifyListeners();
  }
}

/// A ValueNotifier-style model that opts into recording values.
class SearchQuery extends ValueNotifier<String>
    with OTelChangeNotifierMixin {
  SearchQuery(super.initial);

  // ✨ Span: `notifier.notify:SearchQuery` also carries
  //    `notifier.value` (clipped) and `notifier.value.type`.
  //    Off by default because notifier values often carry user data.
  @override
  bool get otelRecordValues => true;

  @override
  int get otelValueMaxLength => 64;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bring up OTel before runApp so spans flow from the first build.
  // Exports OTLP; point `endpoint` at any OpenTelemetry-compatible
  // collector.
  await OTel.initialize(
    serviceName: 'provider-otel-example',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartModel()),
        ChangeNotifierProvider(create: (_) => SearchQuery('')),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    return Scaffold(
      body: Center(child: Text('items: ${cart.items.length}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<CartModel>().add('thing'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## Span shape

```
notifier.notify:CartModel      notifier.name=CartModel  notifier.event=notify
notifier.notify:SearchQuery    + notifier.value, notifier.value.type
(on provider teardown)
notifier.disposed:CartModel    notifier.event=disposed
```

`notifyListeners()` with no listeners attached emits no span, matching
`ChangeNotifier`'s own dispatch behavior.

A full runnable Flutter app lives in `example_app/` in the repository.
