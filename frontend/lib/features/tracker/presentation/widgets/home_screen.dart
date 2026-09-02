import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/app/app.dart';
import 'package:frontend/core/widgets/pass_through.dart';
import 'package:frontend/features/tracker/presentation/state/passthrough_enabled_notifier.dart';
import 'package:frontend/features/tracker/presentation/widgets/balance_view.dart';
import 'package:frontend/features/tracker/presentation/widgets/entries_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      // spacing: 32,
      children: [
        const Positioned(top: 0, left: 0, right: 0, child: BalanceView()),
        Positioned.fill(
          child: Consumer(
            builder: (context, ref, _) {
              return PassthroughContainer(
                topPassThroughHeight: balanceHeight,
                enabled: ref.watch(passThroughEnabledProvider),
                child: const EntriesView(),
              );
            },
          ),
        ), // Custom scroll view with sizedbox of height BalanceView
      ],
    );
  }
}
