import 'package:fluent_ui/fluent_ui.dart' show FluentApp;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/widgets/liquid_tabbar.dart';

const _items = [
  LiquidGlassTabItem(icon: Icons.home, label: 'A'),
  LiquidGlassTabItem(icon: Icons.list, label: 'B'),
  LiquidGlassTabItem(icon: Icons.bar_chart, label: 'C'),
  LiquidGlassTabItem(icon: Icons.settings, label: 'D'),
];

Future<List<int>> _pump(WidgetTester tester, {int currentIndex = 0}) async {
  final taps = <int>[];
  await tester.pumpWidget(
    FluentApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: LiquidGlassTabBar(
            items: _items,
            currentIndex: currentIndex,
            onTap: taps.add,
          ),
        ),
      ),
    ),
  );
  return taps;
}

/// Drags along the bar from tab [from] by [dx], past the touch slop first so
/// the whole of [dx] moves the pill.
Future<void> _drag(WidgetTester tester, int from, double dx) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.text(_items[from].label)),
  );
  const slop = 20.0;
  await gesture.moveBy(Offset(dx.sign * slop, 0));
  await tester.pump();
  await gesture.moveBy(Offset(dx - dx.sign * slop, 0));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dragging two tabs over snaps to that tab', (tester) async {
    final taps = await _pump(tester);
    await _drag(tester, 0, 200);
    expect(taps.last, 2);
  });

  testWidgets('dragging past the end snaps to the last tab', (tester) async {
    final taps = await _pump(tester);
    await _drag(tester, 0, 600);
    expect(taps.last, 3);
  });

  testWidgets('dragging back to the first tab selects it', (tester) async {
    final taps = await _pump(tester, currentIndex: 2);
    await _drag(tester, 2, -200);
    expect(taps.last, 0);
  });
}
