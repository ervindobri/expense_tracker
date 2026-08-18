// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:frontend/widgetbook/use_cases/blurred_container.dart'
    as _frontend_widgetbook_use_cases_blurred_container;
import 'package:frontend/widgetbook/use_cases/buttons.dart'
    as _frontend_widgetbook_use_cases_buttons;
import 'package:frontend/widgetbook/use_cases/tab_bars.dart'
    as _frontend_widgetbook_use_cases_tab_bars;
import 'package:widgetbook/widgetbook.dart' as _widgetbook;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookFolder(
    name: 'core',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'widgets',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'BlurredContainer',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _frontend_widgetbook_use_cases_blurred_container
                    .blurredContainerUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'ExpenseIncomeTabBar',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Expense / Income',
                builder:
                    _frontend_widgetbook_use_cases_tab_bars.pillTabBarUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'LiquidGlassTabBar',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _frontend_widgetbook_use_cases_tab_bars.liquidTabBarUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'PrimaryButton',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _frontend_widgetbook_use_cases_buttons.primaryButtonUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'SecondaryButton',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _frontend_widgetbook_use_cases_buttons
                    .secondaryButtonUseCase,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
