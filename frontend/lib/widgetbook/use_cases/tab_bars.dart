import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/liquid_tabbar.dart';
import 'package:frontend/core/widgets/pill_tabbar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Expense / Income',
  type: ExpenseIncomeTabBar,
  path: 'core/widgets',
)
Widget pillTabBarUseCase(BuildContext context) {
  return Center(
    child: ExpenseIncomeTabBar<String>(
      items: const ['Expense', 'Income'],
      itemToString: (value) => value,
      itemWidth: context.knobs.double.slider(
        label: 'Item width',
        initialValue: 120,
        min: 60,
        max: 200,
      ),
      onChanged: (_) {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'Default',
  type: LiquidGlassTabBar,
  path: 'core/widgets',
)
Widget liquidTabBarUseCase(BuildContext context) {
  return Align(
    alignment: Alignment.bottomCenter,
    child: LiquidGlassTabBar(
      currentIndex: context.knobs.int.slider(
        label: 'Current index',
        initialValue: 0,
        max: 2,
      ),
      height: context.knobs.double.slider(
        label: 'Height',
        initialValue: 64,
        min: 48,
        max: 96,
      ),
      blurSigma: context.knobs.double.slider(
        label: 'Blur sigma',
        initialValue: 12,
        max: 40,
      ),
      items: const [
        LiquidGlassTabItem(icon: LucideIcons.home, label: 'Home'),
        LiquidGlassTabItem(icon: LucideIcons.chartLine, label: 'Stats'),
        LiquidGlassTabItem(icon: LucideIcons.settings, label: 'Settings'),
      ],
      onTap: (_) {},
    ),
  );
}
