import 'package:flutter/material.dart';

import 'formations/offense_formations.dart';
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
  OffenseFormation formation = OffenseFormation.custom;
  int? selected;
  bool showDefense = true;

  @override
  void initState() {
    super.initState();
    positions = List<Offset>.from(widget.initialPositions);
  }

  void _savePositions() =>
      widget.onPositionsChanged(List<Offset>.from(positions));

  void _applyFormation(OffenseFormation next) {
    if (next == OffenseFormation.custom) {
      return;
    }
    final preset = offenseFormationPositions(next);
    setState(() {
      for (var i = 0; i < 11; i++) {
        positions[i] = preset[i];
      }
      formation = next;
      selected = null;
    });
    _savePositions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
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
                    onChanged: (value) => setState(() {
                      showDefense = value;
                      selected = null;
                    }),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Text(
                    'Offense:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<OffenseFormation>(
                      key: ValueKey(formation),
                      initialValue: formation,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: OffenseFormation.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                          .toList(),
                      onChanged: (next) {
                        if (next != null && next != OffenseFormation.custom) {
                          _applyFormation(next);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Text(
                'Spieler antippen und ziehen. Blau = Offense, Rot = Defense. '
                'Formationen ändern nur die Offense.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
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
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) =>
                          selectAt(details.localPosition, fieldSize),
                      onPanUpdate: (details) {
                        if (selected == null) {
                          return;
                        }
                        setState(() {
                          positions[selected!] = Offset(
                            (details.localPosition.dx / fieldSize.width).clamp(
                              .03,
                              .97,
                            ),
                            (details.localPosition.dy / fieldSize.height).clamp(
                              .03,
                              .97,
                            ),
                          );
                          if (selected! < 11) {
                            formation = OffenseFormation.custom;
                          }
                        });
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
                          offenseFormation: formation,
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
                          : selected! < 11
                          ? 'Offense: ${offenseLabelAt(selected!, formation)}'
                          : 'Defense: ${defenseLabels[selected! - 11]}',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => selected = null),
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
      if (!showDefense && i >= 11) {
        continue;
      }
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
