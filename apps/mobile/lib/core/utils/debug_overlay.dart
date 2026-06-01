import 'package:flutter/material.dart';

class DebugOverlay extends StatefulWidget {
  final Widget child;
  const DebugOverlay({super.key, required this.child});

  static final List<String> _logs = [];
  static OverlayEntry? _entry;
  static bool _visible = false;

  static void log(String msg) {
    final time = DateTime.now().toString().substring(11, 19);
    _logs.insert(0, '[$time] $msg');
    if (_logs.length > 50) _logs.removeLast();
    _entry?.markNeedsBuild();
  }

  static void show(BuildContext context) {
    if (_entry != null) return;
    _entry = OverlayEntry(builder: (_) => _DebugPanel());
    Overlay.of(context).insert(_entry!);
    _visible = true;
  }

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DebugOverlay.show(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _DebugPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      height: 250,
      child: Material(
        color: Colors.black87,
        child: Column(
          children: [
            Container(
              color: Colors.red,
              padding: const EdgeInsets.all(4),
              child: const Row(
                children: [
                  Text('DEBUG LOG', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: DebugOverlay._logs.length,
                itemBuilder: (_, i) => Text(
                  DebugOverlay._logs[i],
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
