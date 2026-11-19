import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps a zoomable widget (a map, chart or `InteractiveViewer`) so that a
/// plain mouse-wheel scroll scrolls the page instead of zooming the child.
///
/// Holding Ctrl (or Cmd on macOS) while scrolling passes the scroll to the
/// child as usual. Without it, a short hint is shown over the child.
///
/// This works for widgets drawn by Flutter. Platform views (such as the
/// native Google Maps view on web) receive browser events directly; for those
/// use the map's own "cooperative" gesture setting.
class ScrollZoomGuard extends StatefulWidget {
  /// Creates a guard around [child].
  const ScrollZoomGuard({
    super.key,
    required this.child,
    this.enabled = true,
    this.message = 'Use Ctrl + scroll to zoom',
    this.macMessage = 'Use ⌘ + scroll to zoom',
    this.hintDuration = const Duration(milliseconds: 1500),
    this.scrollParent = true,
    this.hintBuilder,
  });

  /// The zoomable widget.
  final Widget child;

  /// Whether the guard is active.
  final bool enabled;

  /// Hint shown on Windows and Linux.
  final String message;

  /// Hint shown on macOS.
  final String macMessage;

  /// How long the hint stays visible after the last blocked scroll.
  final Duration hintDuration;

  /// Whether blocked scrolls are passed to the nearest scrollable ancestor.
  final bool scrollParent;

  /// Builds a custom hint from the message.
  final Widget Function(BuildContext context, String message)? hintBuilder;

  /// Whether the zoom modifier (Ctrl, or Cmd on macOS) is held.
  static bool get isModifierPressed {
    final keyboard = HardwareKeyboard.instance;
    return keyboard.isControlPressed || keyboard.isMetaPressed;
  }

  @override
  State<ScrollZoomGuard> createState() => _ScrollZoomGuardState();
}

class _ScrollZoomGuardState extends State<ScrollZoomGuard> {
  bool _showHint = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onSignal(PointerSignalEvent event) {
    if (!widget.enabled || event is! PointerScrollEvent) return;
    if (ScrollZoomGuard.isModifierPressed) return;

    // This listener sits above the child, so it registers first and wins:
    // the child never sees the scroll.
    GestureBinding.instance.pointerSignalResolver.register(event, (e) {
      final scroll = e as PointerScrollEvent;
      if (widget.scrollParent) {
        final position = Scrollable.maybeOf(context)?.position;
        if (position != null) {
          final delta = position.axis == Axis.vertical
              ? scroll.scrollDelta.dy
              : scroll.scrollDelta.dx;
          position.pointerScroll(delta);
        }
      }
      _flashHint();
    });
  }

  void _flashHint() {
    _timer?.cancel();
    if (!_showHint) setState(() => _showHint = true);
    _timer = Timer(widget.hintDuration, () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMac = Theme.of(context).platform == TargetPlatform.macOS;
    final message = isMac ? widget.macMessage : widget.message;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerSignal: _onSignal,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _showHint ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: widget.hintBuilder?.call(context, message) ??
                  ColoredBox(
                    color: const Color(0x73000000),
                    child: Center(
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
