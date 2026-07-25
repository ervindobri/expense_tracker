import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart'
    hide Tooltip, IconButton, ElevatedButton, TextButton;
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/widgets/pass_through.dart';
import 'package:frontend/core/widgets/primary_button.dart';
import 'package:frontend/features/tracker/presentation/state/balance_provider.dart';
import 'package:frontend/features/tracker/presentation/state/passthrough_enabled_notifier.dart';
import 'package:frontend/features/tracker/presentation/state/report_notifier.dart';
import 'package:frontend/features/tracker/presentation/widgets/balance_view.dart';
import 'package:frontend/features/tracker/presentation/widgets/entries_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return FluentApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const HomeShell(),
    );
  }
}

/// Below this width the app switches to the phone layout (stacked search
/// header, result cards instead of the table).
const kCompactBreakpoint = 700.0;

bool isCompactLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kCompactBreakpoint;

const balanceHeight = 300.0;

class HomeShell extends HookConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(reportProvider);
    final balance = ref.watch(balanceProvider(month)).value;
    return Scaffold(
      backgroundColor: FluentTheme.of(context).scaffoldBackgroundColor,
      floatingActionButton: balance?.incomes == 0.0
          ? PrimaryButton(onPressed: () {}, label: "Add income")
          : const SizedBox(),
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Stack(
          alignment: Alignment.topCenter,
          fit: StackFit.expand,
          // spacing: 32,
          children: [
            Positioned(top: 0, left: 0, right: 0, child: const BalanceView()),
            Positioned.fill(
              child: PassthroughContainer(
                topPassThroughHeight: balanceHeight,
                enabled: ref.watch(passThroughEnabledProvider),
                child: const EntriesView(),
              ),
            ), // Custom scroll view with sizedbox of height BalanceView
          ],
        ),
      ),
    );
  }
}
