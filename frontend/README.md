# frontend

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Widgetbook

The component catalog lives in [`lib/widgetbook/`](lib/widgetbook/). Run it with:

```bash
fvm flutter run -t lib/widgetbook/main.dart -d chrome
```

Use cases are annotated with `@widgetbook.UseCase` and collected into
`lib/widgetbook/main.directories.g.dart` by the generator, so after adding or
renaming one re-run:

```bash
fvm dart run build_runner build
```

Addons wired up: a Fluent theme switcher (`AppTheme.light` / `AppTheme.dark`),
an `easy_localization`-backed locale switcher, viewport, alignment and text
scale. `test/widgetbook_smoke_test.dart` boots the catalog and renders one use
case, which catches broken use cases in CI.
