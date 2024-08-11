import 'package:flutter/material.dart';

class App extends StatefulWidget {
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _isHovering = false;
  @override
  Widget build(BuildContext context) {
    return
        // appBar: AppBar(title: Text('Hover Popup Example')),
        MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        width: 200,
        height: 100,
        color: _isHovering ? Colors.blue : Colors.green,
        child: Center(
          child: Text(
            _isHovering ? 'Hovering' : 'Not Hovering',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _showPopupMenu(BuildContext context, Offset offset) {
    final RenderBox overlay =
        Overlay.of(context)!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        offset,
        offset.translate(50.0, 150.0), // Adjust according to your requirement
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      items: <PopupMenuEntry>[
        PopupMenuItem(
          child: ElevatedButton(
            onPressed: () {},
            child: Text('Button 1'),
          ),
        ),
        PopupMenuItem(
          child: ElevatedButton(
            onPressed: () {},
            child: Text('Button 2'),
          ),
        ),
        // Add more buttons as needed
      ],
    );
  }
}
