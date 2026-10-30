import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// How far past the release point a press counts as complete. A tap lets go
/// before the swell has risen, so the rise finishes first and only then does
/// the widget spring back, as FlClash's dock lens does.
const double _liftSnap = 0.975;

final SpringDescription _pressSpring = SpringDescription.withDampingRatio(
  mass: 1,
  stiffness: 311,
  ratio: 0.593,
);

/// Swells its child under a finger with a spring, then springs back on release.
///
/// The swell is a paint-time transform, so layout, hit testing and anything
/// anchored to the child stay at rest. Pair it with a splash-free button
/// surface so the swell is the only feedback, the way FlClash does it.
class ElasticPress extends StatefulWidget {
  const ElasticPress({
    super.key,
    required this.child,
    this.enabled = true,
    this.maxGrowth = 16,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final bool enabled;

  /// Pixels the longest side may gain at a full press. Small targets cap at a
  /// quarter of their size, so icons pop without leaving their slot.
  final double maxGrowth;
  final Alignment alignment;

  @override
  State<ElasticPress> createState() => _ElasticPressState();
}

class _ElasticPressState extends State<ElasticPress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lift = AnimationController.unbounded(
    vsync: this,
  );
  int? _pointer;
  bool _releasing = false;
  double _growth = .04;

  @override
  void initState() {
    super.initState();
    _lift.addListener(_settle);
  }

  @override
  void dispose() {
    _lift.dispose();
    super.dispose();
  }

  void _springTo(double target) {
    _lift.animateWith(
      SpringSimulation(_pressSpring, _lift.value, target, _lift.velocity),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.enabled ||
        _pointer != null ||
        event.buttons & kPrimaryButton == 0) {
      return;
    }
    _pointer = event.pointer;
    _releasing = false;
    final side = context.size?.longestSide ?? 0;
    _growth = side <= 0 ? .04 : math.min(.25, widget.maxGrowth / side);
    _springTo(1);
  }

  void _handlePointerEnd(PointerEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    _releasing = true;
    _settle();
  }

  void _settle() {
    if (!_releasing || _lift.value < _liftSnap) return;
    _releasing = false;
    _springTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerEnd,
      onPointerCancel: _handlePointerEnd,
      child: AnimatedBuilder(
        animation: _lift,
        // Always the same shape around the child, even at rest: swapping the
        // child in and out of a Transform disposes its gesture recognizers on
        // the frame after the press starts, which swallows that first tap.
        builder: (context, child) => Transform.scale(
          scale: 1 + _lift.value * _growth,
          alignment: widget.alignment,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
