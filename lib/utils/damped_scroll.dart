import 'dart:async';

import 'package:flutter/material.dart';

class DampedScrollPhysics extends ScrollPhysics {
  const DampedScrollPhysics({super.parent, this.dragDamping = 0.78, this.velocityDamping = 0.88});

  final double dragDamping;
  final double velocityDamping;

  @override
  DampedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return DampedScrollPhysics(
      parent: buildParent(ancestor),
      dragDamping: dragDamping,
      velocityDamping: velocityDamping,
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    final base = super.applyPhysicsToUserOffset(position, offset);
    return base * dragDamping;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    return super.createBallisticSimulation(position, velocity * velocityDamping);
  }
}

class DampedScrollController extends ScrollController {
  DampedScrollController({
    this.wheelDamping = 0.55,
    this.wheelAnimDuration = const Duration(milliseconds: 120),
  });

  final double wheelDamping;
  final Duration wheelAnimDuration;

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition? oldPosition) {
    return DampedScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      wheelDamping: wheelDamping,
      wheelAnimDuration: wheelAnimDuration,
    );
  }
}

class DampedScrollPosition extends ScrollPositionWithSingleContext {
  DampedScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    required this.wheelDamping,
    required this.wheelAnimDuration,
  });

  final double wheelDamping;
  final Duration wheelAnimDuration;

  double? _wheelTarget;
  int _wheelSeq = 0;

  @override
  void pointerScroll(double delta) {
    if (delta == 0) return;

    final base = _wheelTarget ?? pixels;
    final target = (base + delta * wheelDamping).clamp(minScrollExtent, maxScrollExtent);
    _wheelTarget = target;

    final seq = ++_wheelSeq;
    unawaited(
      animateTo(
        _wheelTarget!,
        duration: wheelAnimDuration,
        curve: Curves.easeOutCubic,
      ).catchError((_) {}).whenComplete(() {
        if (seq == _wheelSeq) {
          _wheelTarget = null;
        }
      }),
    );
  }
}
