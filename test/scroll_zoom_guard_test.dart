import 'package:ctrl_scroll_zoom_guard/ctrl_scroll_zoom_guard.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int childScrolls;

  Widget app({bool enabled = true}) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 200,
              child: ScrollZoomGuard(
                enabled: enabled,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerSignal: (e) => GestureBinding
                      .instance.pointerSignalResolver
                      .register(e, (_) => childScrolls++),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> scroll(WidgetTester tester) async {
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    final center = tester.getCenter(find.byType(ScrollZoomGuard));
    await tester.sendEventToBinding(pointer.hover(center));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 40)));
    await tester.pump();
  }

  setUp(() => childScrolls = 0);

  testWidgets('when disabled, scrolls reach the child', (tester) async {
    await tester.pumpWidget(app(enabled: false));
    await scroll(tester);
    expect(childScrolls, 1);
  });

  testWidgets('blocks plain scrolls and shows the hint', (tester) async {
    await tester.pumpWidget(app());
    await scroll(tester);
    expect(childScrolls, 0);
    AnimatedOpacity hint() =>
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(hint().opacity, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(hint().opacity, 0);
  });

  testWidgets('lets Ctrl + scroll through to the child', (tester) async {
    await tester.pumpWidget(app());
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    expect(ScrollZoomGuard.isModifierPressed, isTrue);
    await scroll(tester);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(childScrolls, 1);
  });
}
