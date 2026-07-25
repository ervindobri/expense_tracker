import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/material.dart';

class ExpenseIncomeTabBar<T> extends StatefulWidget {
  final T? initialTab;
  final ValueChanged<T> onChanged;
  final String Function(T val) itemToString;
  final List<T> items;

  const ExpenseIncomeTabBar({
    super.key,
    required this.onChanged,
    this.initialTab,
    required this.itemToString,
    required this.items,
  });

  @override
  State<ExpenseIncomeTabBar> createState() => _ExpenseIncomeTabBarState<T>();
}

class _ExpenseIncomeTabBarState<T> extends State<ExpenseIncomeTabBar<T>> {
  late T _selected;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null){
      _selected = widget.initialTab as T;
    }
    else {
      _selected = widget.items.first;
    }
  }

  void _select(T tab) {
    if (tab == _selected) return;
    setState(() => _selected = tab);
    widget.onChanged(tab);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      decoration: BoxDecoration(
      color: FluentTheme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(32.0)
      ),
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = 120.0;
          return Stack(
            children: [
              // Sliding highlight
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                left: _selected == widget.items.first ? 0 : tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: FluentTheme.of(context).inactiveBackgroundColor,
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ),
              // Tap targets + labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ...widget.items.map(
                    (e) => InkWell(
                      splashColor: Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                      onTap: () => _select(e),
                      // behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: tabWidth,
                        height: 32,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.itemToString(e),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
