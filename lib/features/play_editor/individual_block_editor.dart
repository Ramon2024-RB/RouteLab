import 'package:flutter/material.dart';

enum IndividualBlockTechnique {
  drive,
  reach,
  down,
  doubleTeam,
  pull,
  passProtection,
}

extension IndividualBlockTechniqueLabel on IndividualBlockTechnique {
  String get label => switch (this) {
    IndividualBlockTechnique.drive => 'Drive Block',
    IndividualBlockTechnique.reach => 'Reach Block',
    IndividualBlockTechnique.down => 'Down Block',
    IndividualBlockTechnique.doubleTeam => 'Double Team',
    IndividualBlockTechnique.pull => 'Pull',
    IndividualBlockTechnique.passProtection => 'Pass Protection',
  };
}

class IndividualBlockResult {
  const IndividualBlockResult({
    required this.techniqueName,
    required this.points,
    required this.chooseTarget,
  });

  final String techniqueName;
  final List<Offset> points;
  final bool chooseTarget;
}

class IndividualBlockEditor extends StatefulWidget {
  const IndividualBlockEditor({
    super.key,
    required this.playerIndex,
    required this.positions,
    required this.onApply,
  });

  final int playerIndex;
  final List<Offset> positions;
  final ValueChanged<IndividualBlockResult> onApply;

  @override
  State<IndividualBlockEditor> createState() => _IndividualBlockEditorState();
}

class _IndividualBlockEditorState extends State<IndividualBlockEditor> {
  IndividualBlockTechnique technique = IndividualBlockTechnique.drive;
  bool left = false;

  List<Offset> _points() {
    final sign = left ? -1.0 : 1.0;

    switch (technique) {
      case IndividualBlockTechnique.drive:
        return const [Offset.zero, Offset(0, -.065)];

      case IndividualBlockTechnique.reach:
        return [
          Offset.zero,
          Offset(sign * .035, -.025),
          Offset(sign * .075, -.075),
        ];

      case IndividualBlockTechnique.down:
        return [Offset.zero, Offset(sign * .035, -.055)];

      case IndividualBlockTechnique.doubleTeam:
        return [Offset.zero, Offset(sign * .045, -.045)];

      case IndividualBlockTechnique.pull:
        return [
          Offset.zero,
          const Offset(0, .065),
          Offset(sign * .10, .09),
          Offset(sign * .20, .065),
          Offset(sign * .25, -.085),
        ];

      case IndividualBlockTechnique.passProtection:
        return [
          Offset.zero,
          Offset(sign * .025, .035),
          Offset(sign * .045, .055),
        ];
    }
  }

  void _apply(bool chooseTarget) {
    widget.onApply(
      IndividualBlockResult(
        techniqueName: '${technique.label} ${left ? "links" : "rechts"}',
        points: _points(),
        chooseTarget: chooseTarget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7BDCC0);
    const background = Color(0xFF102219);

    return Container(
      color: background,
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Row(
              children: [
                Icon(Icons.shield_outlined, color: accent),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Individueller Blocking-Editor',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Wähle eine Technik und anschließend, '
              'ob du nur die Bewegung oder ein konkretes '
              'Blockziel festlegen möchtest.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 20),
            const Text(
              'Blocking-Technik',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in IndividualBlockTechnique.values)
                  ChoiceChip(
                    label: Text(item.label),
                    selected: technique == item,
                    onSelected: (_) {
                      setState(() => technique = item);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Richtung',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Links'),
                  icon: Icon(Icons.arrow_back),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Rechts'),
                  icon: Icon(Icons.arrow_forward),
                ),
              ],
              selected: {left},
              onSelectionChanged: (value) {
                setState(() => left = value.first);
              },
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => _apply(false),
              icon: const Icon(Icons.check),
              label: const Text('Blocking anwenden'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _apply(true),
              icon: const Icon(Icons.my_location),
              label: const Text('Verteidiger als Blockziel wählen'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Manuelle Blocks ersetzen die automatische '
              'Aufgabe des ausgewählten Linemans. '
              'Die anderen Linemen bleiben unverändert.',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
