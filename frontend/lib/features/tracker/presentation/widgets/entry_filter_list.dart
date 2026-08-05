import 'package:fluent_ui/fluent_ui.dart' hide Scrollbar;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/build_context.dart';
import 'package:frontend/core/extensions/string.dart';
import 'package:frontend/features/tracker/domain/models/entry.dart';

class FilterChipList<T> extends StatefulWidget {
  const FilterChipList({
    super.key,
    required this.initialList,
    required this.onPressed,
    required this.onDeleted,
  });
  final List<T> initialList;
  final void Function(T) onPressed;
  final void Function(T) onDeleted;

  @override
  State<FilterChipList> createState() => _FilterChipListState<T>();
}

class _FilterChipListState<T> extends State<FilterChipList<T>> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  late List<T> _filters;
  final controller = ScrollController();

  @override
  void initState() {
    _filters = List<T>.from(widget.initialList);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: Durations.short3,
        curve: Curves.decelerate,
      );
    });
    super.initState();
  }

  void _addFilter(T item) {
    final index = _filters.length;
    _filters.add(item);
    _listKey.currentState?.insertItem(
      index,
      duration: const Duration(milliseconds: 150),
    );
  }

  void _removeFilter(int index) {
    final removed = _filters.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildChip(index, removed, animation),
      duration: const Duration(milliseconds: 150),
    );
  }

  Widget _buildChip(int index, T item, Animation<double> animation) {
    // Combine a size + fade transition so the chip grows in from
    // zero width rather than popping in instantly.
    final theme = Theme.of(context).textTheme;
    return ScaleTransition(
      scale: animation,
      alignment: Alignment.center,
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: FilterChip.elevated(
            backgroundColor: FluentTheme.of(context).chipColor,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            deleteIconColor: FluentTheme.of(context).inverseTextColor,
            label: item.runtimeType == Entry
                ? Text(
                    (item as Entry).amount.formatCurrency,
                    style: theme.bodyMedium?.copyWith(
                      color: FluentTheme.of(context).inverseTextColor,
                    ),
                  )
                : Text(item.toString()),
            onSelected: (_) {
              widget.onPressed(item);
            },
            onDeleted: () {
              _removeFilter(index);
              widget.onDeleted(item);
            },
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant FilterChipList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialList.length > _filters.length) {
      // Only the items that are actually new, in order.
      final newItems = widget.initialList.sublist(_filters.length);
      newItems.forEach(_addFilter);

      if (controller.hasClients && _filters.length > 2) {
        controller.animateTo(
          controller.position.maxScrollExtent + 120,
          duration: Durations.short3,
          curve: Curves.bounceIn,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: context.width,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 48 + (kIsWeb ? 36.0 : 0.0),
        child: Scrollbar(
          controller: controller,
          thickness: 12.0,
          child: AnimatedList(
            key: _listKey,
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: kIsWeb ? 12.0 : 0.0,
            ),
            initialItemCount: _filters.length,
            itemBuilder: (context, index, animation) {
              return _buildChip(index, _filters[index], animation);
            },
          ),
        ),
      ),
    );
  }
}
