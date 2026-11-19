import 'package:ctrl_scroll_zoom_guard/ctrl_scroll_zoom_guard.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: DemoPage()));

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ctrl_scroll_zoom_guard')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Scroll the page over the map. Hold Ctrl (⌘) to zoom.'),
          const SizedBox(height: 16),
          SizedBox(
            height: 360,
            child: ScrollZoomGuard(
              child: InteractiveViewer(
                maxScale: 6,
                child: Container(
                  color: const Color(0xFFDDE8F0),
                  child: const Center(
                    child: Icon(Icons.map, size: 160, color: Colors.blueGrey),
                  ),
                ),
              ),
            ),
          ),
          for (var i = 0; i < 20; i++)
            ListTile(title: Text('Page content ${i + 1}')),
        ],
      ),
    );
  }
}
