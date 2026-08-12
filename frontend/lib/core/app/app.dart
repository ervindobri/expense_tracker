import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart'
    hide Tooltip, IconButton, ElevatedButton, TextButton;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/helpers/tab_title_changer.dart';
import 'package:frontend/core/helpers/toastification_service.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/core/network/internet_connection_provider.dart';
import 'package:frontend/core/storage/shared_prefs_provider.dart';
import 'package:frontend/core/widgets/animated_indexed_stack.dart';
import 'package:frontend/core/widgets/liquid_tabbar.dart';
import 'package:frontend/core/widgets/pass_through.dart';
import 'package:frontend/core/widgets/primary_button.dart';
import 'package:frontend/features/settings/presentation/settings_screen.dart';
import 'package:frontend/features/stats/presentation/stats_screen.dart';
import 'package:frontend/features/tracker/presentation/state/balance_provider.dart';
import 'package:frontend/features/tracker/presentation/state/categories_provider.dart';
import 'package:frontend/features/tracker/presentation/state/entries_provider.dart';
import 'package:frontend/features/tracker/presentation/state/passthrough_enabled_notifier.dart';
import 'package:frontend/features/tracker/presentation/state/report_notifier.dart';
import 'package:frontend/features/tracker/presentation/widgets/balance_view.dart';
import 'package:frontend/features/tracker/presentation/widgets/entries_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';


class MyCustomScrollBehavior extends MaterialScrollBehavior {
  const MyCustomScrollBehavior();
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    // etc.
  };
}
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return FluentApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      scrollBehavior: const MyCustomScrollBehavior(),
      themeMode: themeMode,
      locale: context.locale,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
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
    final balance = ref.watch(balanceProvider(month));
    final tab = useState(0);

    final categories = ref.watch(categoriesProvider);
    final entries = ref.watch(entriesProvider);



    if (!kIsWeb) {
      // trigger rebuild
      ref.watch(sharedPrefsProvider);
    
      ref.watch(internetConnectionProvider);

      ref.listen<InternetConnectionStatus>(internetConnectionProvider, (
        _,
        next,
      ) {
        if (next == InternetConnectionStatus.offline) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ToastificationService.showError(
              context: context,
              title: LocaleKeys.no_internet_connection.tr(),
              description: LocaleKeys.please_check_connection.tr(),
            );
          });
        }
      });
    }

    final tabTitleReminder = ref.watch(tabTitleChangerProvider);
    useEffect(() {
      tabTitleReminder.start();
      return () => tabTitleReminder.dispose();
    }, []);
    return Scaffold(
      backgroundColor: FluentTheme.of(context).scaffoldBackgroundColor,
      floatingActionButton: balance.value?.incomes == 0.0
          ? PrimaryButton(onPressed: () {}, label: LocaleKeys.add_income.tr())
          : const SizedBox(),
      extendBody: true,
      bottomNavigationBar: LiquidGlassTabBar(
        indicatorColor: FluentTheme.of(context).indicatorColor,
        items: [
          LiquidGlassTabItem(
            icon: LucideIcons.home,
            label: LocaleKeys.home.tr(),
          ),
          LiquidGlassTabItem(
            icon: LucideIcons.chartLine,
            label: LocaleKeys.stats.tr(),
          ),
          LiquidGlassTabItem(
            icon: LucideIcons.settings,
            label: LocaleKeys.settings.tr(),
          ),
        ],
        currentIndex: tab.value,
        onTap: (i) => tab.value = i,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: AnimatedIndexedStack(
                index: tab.value,
                children: [
                  Stack(
                    alignment: Alignment.topCenter,
                    // spacing: 32,
                    children: [
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: BalanceView(),
                      ),
                      Positioned.fill(
                        child: PassthroughContainer(
                          topPassThroughHeight: balanceHeight,
                          enabled: ref.watch(passThroughEnabledProvider),
                          child: const EntriesView(),
                        ),
                      ), // Custom scroll view with sizedbox of height BalanceView
                    ],
                  ),
                  const StatsScreen(),
                  const SettingsScreen(),
                ],
              ),
            ),
          ),

          if ((balance.isLoading ||
                  categories.isLoading ||
                  entries.isLoading) ||
              balance.value == null)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
