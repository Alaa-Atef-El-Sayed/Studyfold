import 'package:flutter/material.dart';

class TwoFingerInteractiveView extends StatefulWidget {
  const TwoFingerInteractiveView({Key? key, required this.child})
    : super(key: key);

  final Widget child;

  @override
  _TwoFingerInteractiveViewState createState() =>
      _TwoFingerInteractiveViewState();
}

class _TwoFingerInteractiveViewState extends State<TwoFingerInteractiveView> {
  final Set<int> _pointers = {};
  // A flag to control other gestures, if necessary (e.g., single-finger drawing)
  bool _isTwoFingersDown = false;

  void _handlePointerDown(PointerDownEvent event) {
    setState(() {
      _pointers.add(event.pointer);
      _updateTwoFingerStatus();
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    setState(() {
      _pointers.remove(event.pointer);
      _updateTwoFingerStatus();
    });
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    setState(() {
      _pointers.remove(event.pointer);
      _updateTwoFingerStatus();
    });
  }

  void _updateTwoFingerStatus() {
    _isTwoFingersDown = _pointers.length >= 2;
    // You can use this status to toggle the physics of a surrounding scroll view
    // or the enabled state of a single-finger GestureDetector.
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: InteractiveViewer(
        // InteractiveViewer handles pinch-to-zoom and pan with two fingers by default.
        // It enters the gesture arena and typically wins against single-finger gestures
        // when two fingers are used.

        // If you had a single-finger specific detector (e.g., for drawing or tapping),
        // you would manage its behavior here.
        // Example: If wrapping this in a PageView, you'd disable the PageView's physics.
        // physics: _isTwoFingersDown ? const NeverScrollableScrollPhysics() : null, // (Conceptual usage for parent widgets)
        child: widget.child,
      ),
    );
  }
}
