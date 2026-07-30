import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/extensions/build_context.dart';
import 'package:frontend/core/extensions/string.dart';

/// One slice of the donut (e.g. a spending category).
class ExpenseSegment<T> {
  const ExpenseSegment({
    required this.label,
    required this.amount,
    required this.color,
    required this.item,
  });
  final String label;
  final double amount;
  final Color color;
  final T item;
}

typedef IntCallback = void Function(int?);

/// A donut chart with gapped sections, a center total, and a floating
/// percentage badge on the tapped/hovered slice — modeled on the
/// "Expenses Report" ring chart.
///
/// Usage:
/// ```dart
/// ExpenseDonutChart(
///   segments: const [
///     ExpenseSegment(label: 'Groceries', amount: 13200, color: Colors.deepPurple),
///     ExpenseSegment(label: 'Transport', amount: 8100, color: Colors.blue),
///     ExpenseSegment(label: 'Entertainment', amount: 6400, color: Colors.green),
///     ExpenseSegment(label: 'Bills', amount: 9600, color: Colors.orange),
///   ],
/// )
/// ```
class ExpenseDonutChart<T> extends StatefulWidget {
  const ExpenseDonutChart({
    super.key,
    required this.segments,
    this.centerLabel = 'Total',
    this.selected,
    this.totalFormatter = _defaultTotalFormatter,
    this.onTouched,
  });
  final List<ExpenseSegment<T>> segments;
  final String centerLabel;
  final T? selected;
  final IntCallback? onTouched;

  /// Formats the bold total text in the center (e.g. "42 124 Ft").
  final String Function(double total) totalFormatter;

  static String _defaultTotalFormatter(double total) {
    final rounded = total.round();
    final digits = rounded.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buffer.write(' ');
      }
    }
    return '$buffer Ft';
  }

  @override
  State<ExpenseDonutChart> createState() => _ExpenseDonutChartState();
}

class _ExpenseDonutChartState extends State<ExpenseDonutChart> {
  int? _touchedIndex;

  double get _total => widget.segments.fold(0.0, (sum, s) => sum + s.amount);

  @override
  void didUpdateWidget(ExpenseDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      // selected
      setState(() {
        if (widget.selected == null) {
          _touchedIndex = null;
        } else {
          _touchedIndex = widget.segments.indexWhere(
            (e) => e.item == widget.selected,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 4,
              centerSpaceRadius: 90,
              borderData: FlBorderData(border: Border.all(color: Colors.white)),
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  final section = response?.touchedSection;
                  setState(() {
                    _touchedIndex =
                        (!event.isInterestedForInteractions || section == null)
                        ? null
                        : section.touchedSectionIndex;
                  });

                  widget.onTouched?.call(
                    event.isInterestedForInteractions
                        ? section?.touchedSectionIndex != -1
                              ? section?.touchedSectionIndex
                              : null
                        : null,
                  );
                },
              ),
              sections: _buildSections(),
            ),
          ),
          _buildCenterText(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    return List.generate(widget.segments.length, (i) {
      final segment = widget.segments[i];
      final isTouched = i == _touchedIndex;

      return PieChartSectionData(
        value: segment.amount <= 0 ? 0.001 : segment.amount,
        color: segment.color,
        radius: isTouched ? 48 : 40,
        cornerRadius: 8.0,
        showTitle: false,
        // Pushes the badge outward past the ring, roughly where a
        // finger/cursor would sit over the slice.
        badgePositionPercentageOffset: 1.35,
      );
    });
  }

  Widget _buildCenterText() {
    return AnimatedSwitcher(
      duration: Durations.short3,
      transitionBuilder: (child, anim) {
        return SlideTransition(
          position: anim.drive(
            Tween(begin: const Offset(0, -0.1), end: Offset.zero),
          ),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      child: Column(
        key: ValueKey(_touchedIndex == null || _touchedIndex == -1),
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          if (_touchedIndex == null || _touchedIndex == -1) ...[
            Text(widget.centerLabel, style: context.bodyLarge),
            Text(widget.totalFormatter(_total), style: context.headlineSmall),
          ] else ...[
            Text(
              widget.segments[_touchedIndex!].label,
              style: context.bodyLarge,
            ),
            Text(
              widget.segments[_touchedIndex!].amount.formatCurrencySymbol(),
              style: context.headlineSmall?.copyWith(
                color: widget.segments[_touchedIndex!].color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// class _PercentBadge extends StatelessWidget {
//   const _PercentBadge({required this.percent, this.color, required this.label});
//   final double percent;
//   final String label;
//   final Color? color;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color:
//             color?.withValues(alpha: 0.3) ??
//             FluentTheme.of(context).indicatorColor,
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: const [
//           BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
//         ],
//       ),
//       child: Row(
//         spacing: 4,
//         mainAxisSize: MainAxisSize.min,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(label),
//           Text('${percent.toStringAsFixed(0)}%', style: context.bodySmall),
//         ],
//       ),
//     );
//   }
// }
