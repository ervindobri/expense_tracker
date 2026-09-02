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
import 'package:frontend/core/widgets/primary_button.dart';
import 'package:frontend/features/settings/presentation/settings_screen.dart';
import 'package:frontend/features/stats/presentation/stats_screen.dart';
import 'package:frontend/features/tracker/presentation/state/balance_provider.dart';
import 'package:frontend/features/tracker/presentation/state/categories_provider.dart';
import 'package:frontend/features/tracker/presentation/state/entries_provider.dart';
import 'package:frontend/features/tracker/presentation/state/report_notifier.dart';
import 'package:frontend/features/tracker/presentation/widgets/home_screen.dart';
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
    final monthlyEntries = ref.watch(monthlyEntriesProvider);

    // Every async source the screens below read from. The UI is only built
    // once all of them carry data, so no screen has to render a half-loaded
    // state.
    final sources = <AsyncValue<Object?>>[
      categories,
      entries,
      monthlyEntries,
      balance,
    ];
    final isReady =
        entries.value != null ||
        sources.every((AsyncValue<Object?> s) => s.hasValue);
    final Object? loadError = sources
        .where((AsyncValue<Object?> s) => s.hasError)
        .firstOrNull
        ?.error;

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
      floatingActionButton: isReady && balance.value?.incomes == 0.0
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
      body: switch ((isReady: isReady, error: loadError)) {
        (isReady: false, error: final Object error?) => _LoadStateView(
          message: LocaleKeys.something_went_wrong.tr(),
          detail: error.toString(),
          onRetry: () {
            ref
              ..invalidate(categoriesProvider)
              ..invalidate(entriesProvider);
          },
        ),
        (isReady: false, error: _) => _LoadStateView(
          message: LocaleKeys.loading_data.tr(),
        ),
        _ => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: AnimatedIndexedStack(
              index: tab.value,
              children: const [HomeScreen(), StatsScreen(), SettingsScreen()],
            ),
          ),
        ),
      },
    );
  }
}

/// Full-screen placeholder shown while the initial data loads, or when that
/// load failed.
class _LoadStateView extends StatelessWidget {
  const _LoadStateView({required this.message, this.detail, this.onRetry});

  final String message;
  final String? detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            if (onRetry == null)
              const SizedBox.square(dimension: 32, child: ProgressRing())
            else
              Icon(
                LucideIcons.circleAlert,
                size: 32,
                color: FluentTheme.of(context).accentColor,
              ),
            Text(message, style: textTheme.titleMedium),
            if (detail != null)
              Text(
                detail!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall,
              ),
            if (onRetry != null)
              PrimaryButton(onPressed: onRetry!, label: LocaleKeys.retry.tr()),
          ],
        ),
      ),
    );
  }
}
