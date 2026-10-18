import 'package:flutter/material.dart';
import 'package:frontend/features/subscriptions/domain/models/subscription.dart';

/// Colored circle with the subscription's initial, the counterpart of the
/// category emoji avatars on the home screen.
class SubscriptionAvatar extends StatelessWidget {
  const SubscriptionAvatar({
    super.key,
    required this.subscription,
    this.radius = 20,
  });

  final Subscription subscription;
  final double radius;

  static const _palette = [
    Colors.deepPurple,
    Colors.blue,
    Colors.teal,
    Colors.deepOrange,
    Colors.pink,
    Colors.indigo,
    Colors.green,
    Color(0xffB09027),
    Colors.cyan,
    Color(0xffE91EE6),
  ];

  @override
  Widget build(BuildContext context) {
    final name = subscription.name.trim();
    final color = _palette[subscription.id.abs() % _palette.length];
    return AnimatedOpacity(
      opacity: subscription.isActive ? 1.0 : 0.45,
      duration: kThemeAnimationDuration,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: color,
        child: Text(
          name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: TextStyle(
            fontSize: radius * 0.9,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}
