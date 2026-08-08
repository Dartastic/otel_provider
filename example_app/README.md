# otel_provider example app

A standalone runnable Flutter demo of `otel_provider` exporting
telemetry over OTLP to any OpenTelemetry-compatible backend.

## Run

```sh
# 1. Have an OTLP/HTTP collector listening on localhost:4318
#    (any OpenTelemetry-compatible collector works), or set
#    OTEL_EXPORTER_OTLP_ENDPOINT to yours.

# 2. Run the app — web is easiest
cd example_app
flutter pub get
flutter run -d chrome
```

(Native targets work too — `flutter run -d macos`, an Android
emulator, etc.)

## What it does

Three buttons drive notifications on two models:

| Button | Model | Span emitted |
|---|---|---|
| "increment counter" | `_Counter` (ChangeNotifier) | `notifier.notify:_Counter` |
| "reset counter" | `_Counter` | `notifier.notify:_Counter` |
| "update message" | `_Message` (ValueNotifier, `recordValues: true`) | `notifier.notify:_Message` with `notifier.value` + `notifier.value.type` |

When the widget tree unmounts, `ChangeNotifierProvider` auto-disposes
the models and you'll also see `notifier.disposed:_Counter` and
`notifier.disposed:_Message`.

## Where to look

In your trace viewer:

- Service name: `provider-otel-example-app`
- Search for `name="notifier.notify:_Counter"` to see every counter
  bump.
- Open any `notifier.notify:_Message` span — `notifier.value` shows
  the actual message string (because the message model opted into
  `recordValues`).

## Env

| Variable | Default | Purpose |
|---|---|---|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://localhost:4318` | OTLP HTTP endpoint. Web targets always use the default (`Platform.environment` is unavailable). |
