import 'package:flutter/material.dart';

import 'painters/football_field_painter.dart';

class PlayEditor extends StatefulWidget {
  const PlayEditor({
    super.key,
    required this.title,
    required this.initialPositions,
    required this.onPositionsChanged,
  });
  final String title;
  final List<Offset> initialPositions;
  final ValueChanged<List<Offset>> onPositionsChanged;

  @override
  State<PlayEditor> createState() => _PlayEditorState();
}

class _PlayEditorState extends State<PlayEditor> {
  late final List<Offset> positions;

  @override
  void initState() {
    super.initState();
    positions = List<Offset>.from(widget.initialPositions);
  }

  void _savePositions() => widget.onPositionsChanged(positions);

  int? selected;
  bool showDefense = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '2D Play Designer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Text('Defense'),
                  Switch(
                    value: showDefense,
                    onChanged: (v) => setState(() {
                      showDefense = v;
                      selected = null;
                    }),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Spieler antippen und ziehen. Blau = Offense, Rot = Defense.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final fieldSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    return GestureDetector(
                      onPanStart: (details) =>
                          selectAt(details.localPosition, fieldSize),
                      onPanUpdate: (details) {
                        if (selected == null) return;
                        setState(
                          () => positions[selected!] = Offset(
                            (details.localPosition.dx / fieldSize.width).clamp(
                              .03,
                              .97,
                            ),
                            (details.localPosition.dy / fieldSize.height).clamp(
                              .03,
                              .97,
                            ),
                          ),
                        );
                      },
                      onPanEnd: (_) => _savePositions(),
                      onPanCancel: _savePositions,
                      onTapDown: (details) =>
                          selectAt(details.localPosition, fieldSize),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: FootballFieldPainter(
                          positions,
                          selected,
                          showDefense,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selected == null
                          ? 'Wähle einen Spieler aus.'
                          : 'Ausgewählt: ${selected! < 11 ? 'Offense' : 'Defense'} #${selected! < 11 ? selected! + 1 : selected! - 10}',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      selected = null;
                    }),
                    icon: const Icon(Icons.check),
                    label: const Text('Fertig'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void selectAt(Offset point, Size size) {
    int? closest;
    var minDistance = 28.0;
    for (var i = 0; i < positions.length; i++) {
      if (!showDefense && i >= 11) continue;
      final p = Offset(
        positions[i].dx * size.width,
        positions[i].dy * size.height,
      );
      final distance = (p - point).distance;
      if (distance < minDistance) {
        closest = i;
        minDistance = distance;
      }
    }
    setState(() => selected = closest);
  }
}
