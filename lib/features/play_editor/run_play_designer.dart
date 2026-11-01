import 'package:flutter/material.dart';

enum RunConcept { insideZone, outsideZone, power, counter, sweep }

extension RunConceptLabel on RunConcept {
  String get label => switch (this) {
    RunConcept.insideZone => 'Inside Zone',
    RunConcept.outsideZone => 'Outside Zone',
    RunConcept.power => 'Power',
    RunConcept.counter => 'Counter',
    RunConcept.sweep => 'Sweep',
  };

  String get description => switch (this) {
    RunConcept.insideZone => 'Direkter Lauf zwischen die Linemen.',
    RunConcept.outsideZone => 'Seitlich anlaufen und nach vorne schneiden.',
    RunConcept.power => 'Kraftvoller Lauf durch eine gewählte Lücke.',
    RunConcept.counter => 'Gegenbewegung, dann Richtungswechsel.',
    RunConcept.sweep => 'Breiter Lauf zur Außenseite.',
  };
}

enum RunDirection { left, right }

extension RunDirectionLabel on RunDirection {
  String get label => this == RunDirection.left ? 'Links' : 'Rechts';
}

enum RunGap { auto, a, b, c, d }

extension RunGapLabel on RunGap {
  String get label => switch (this) {
    RunGap.auto => 'Auto',
    RunGap.a => 'A',
    RunGap.b => 'B',
    RunGap.c => 'C',
    RunGap.d => 'D',
  };
}

class RunPlayResult {
  const RunPlayResult({
    required this.label,
    required this.points,
    required this.concept,
    required this.direction,
    required this.gap,
    required this.withBlocking,
  });

  final String label;
  final List<Offset> points;
  final RunConcept concept;
  final RunDirection direction;
  final RunGap gap;
  final bool withBlocking;
}

class RunPlayDesigner extends StatefulWidget {
  const RunPlayDesigner({
    super.key,
    required this.positions,
    required this.playerIndex,
    required this.onApply,
  });

  final List<Offset> positions;
  final int playerIndex;
  final ValueChanged<RunPlayResult> onApply;

  @override
  State<RunPlayDesigner> createState() => _RunPlayDesignerState();
}

class _RunPlayDesignerState extends State<RunPlayDesigner> {
  RunConcept concept = RunConcept.insideZone;
  RunDirection direction = RunDirection.right;
  RunGap gap = RunGap.auto;
  bool includeBlocking = true;

  RunGap get effectiveGap {
    if (gap != RunGap.auto) return gap;

    return switch (concept) {
      RunConcept.insideZone => RunGap.a,
      RunConcept.outsideZone => RunGap.c,
      RunConcept.power => RunGap.b,
      RunConcept.counter => RunGap.b,
      RunConcept.sweep => RunGap.d,
    };
  }

  Offset _limited(double x, double y) {
    return Offset(x.clamp(.04, .96).toDouble(), y.clamp(.04, .96).toDouble());
  }

  RunPlayResult _buildResult() {
    final start = widget.positions[widget.playerIndex];

    final line = widget.positions.take(5).toList()
      ..sort((a, b) => a.dx.compareTo(b.dx));

    final left = direction == RunDirection.left;
    final sign = left ? -1.0 : 1.0;

    final center = line[2];
    final guard = line[left ? 1 : 3];
    final tackle = line[left ? 0 : 4];

    final lineY = line.map((p) => p.dy).reduce((a, b) => a + b) / line.length;

    final targetX = switch (effectiveGap) {
      RunGap.a => (center.dx + guard.dx) / 2,
      RunGap.b => (guard.dx + tackle.dx) / 2,
      RunGap.c => tackle.dx + sign * .055,
      RunGap.d => tackle.dx + sign * .13,
      RunGap.auto => center.dx,
    };

    final target = targetX.clamp(.05, .95).toDouble();

    final points = <Offset>[start];

    switch (concept) {
      case RunConcept.insideZone:
        points.addAll([
          _limited(start.dx + (target - start.dx) * .60, start.dy - .105),
          _limited(target, lineY + .025),
          _limited(target + sign * .015, lineY - .135),
          _limited(target + sign * .025, lineY - .255),
        ]);

      case RunConcept.outsideZone:
        final stretchX = (target + sign * .045).clamp(.05, .95).toDouble();
        points.addAll([
          _limited(start.dx + sign * .065, start.dy - .055),
          _limited(stretchX, lineY + .09),
          _limited(target, lineY - .045),
          _limited(target + sign * .025, lineY - .23),
        ]);

      case RunConcept.power:
        points.addAll([
          _limited(start.dx + (target - start.dx) * .45, start.dy - .075),
          _limited(target, lineY + .045),
          _limited(target, lineY - .095),
          _limited(target + sign * .02, lineY - .245),
        ]);

      case RunConcept.counter:
        points.addAll([
          _limited(start.dx - sign * .07, start.dy + .005),
          _limited(start.dx - sign * .045, start.dy - .075),
          _limited(target, lineY + .055),
          _limited(target, lineY - .11),
          _limited(target + sign * .015, lineY - .245),
        ]);

      case RunConcept.sweep:
        final edgeX = (tackle.dx + sign * .155).clamp(.05, .95).toDouble();
        points.addAll([
          _limited(start.dx + sign * .105, start.dy - .025),
          _limited(edgeX, lineY + .115),
          _limited(edgeX, lineY - .025),
          _limited(target, lineY - .115),
          _limited(target + sign * .025, lineY - .25),
        ]);
    }

    final relative = points
        .map((p) => Offset(p.dx - start.dx, p.dy - start.dy))
        .toList();

    final label =
        '${concept.label} · ${direction.label} · ${effectiveGap.label}-Gap';

    return RunPlayResult(
      label: label,
      points: relative,
      concept: concept,
      direction: direction,
      gap: effectiveGap,
      withBlocking: includeBlocking,
    );
  }

  Widget _sectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
      children: [
        Row(
          children: [
            Icon(Icons.directions_run, color: accent),
            const SizedBox(width: 10),
            const Text(
              'Run Play Designer',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Laufkonzept, Richtung und Gap unabhängig auswählen.',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 22),

        _sectionTitle('1. Run-Art'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in RunConcept.values)
              ChoiceChip(
                label: Text(item.label),
                selected: concept == item,
                onSelected: (_) {
                  setState(() => concept = item);
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          concept.description,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 22),

        _sectionTitle('2. Laufrichtung'),
        Row(
          children: [
            for (final item in RunDirection.values) ...[
              Expanded(
                child: ChoiceChip(
                  label: SizedBox(
                    width: double.infinity,
                    child: Text(item.label, textAlign: TextAlign.center),
                  ),
                  selected: direction == item,
                  onSelected: (_) {
                    setState(() => direction = item);
                  },
                ),
              ),
              if (item == RunDirection.left) const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 22),

        _sectionTitle('3. Gap'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in RunGap.values)
              ChoiceChip(
                label: Text(item == RunGap.auto ? 'Auto' : '${item.label}-Gap'),
                selected: gap == item,
                onSelected: (_) {
                  setState(() => gap = item);
                },
              ),
          ],
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'OL-Blocking automatisch erstellen',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Passende Blocks für alle fünf Linemen. '
            'Manuelle Blocks bleiben erhalten.',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
          value: includeBlocking,
          onChanged: (value) {
            setState(() => includeBlocking = value);
          },
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1B3428),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ausgewähltes Laufkonzept',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 7),
              Text(
                '${concept.label} · ${direction.label}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ziel: ${effectiveGap.label}-Gap'
                '${gap == RunGap.auto ? ' (automatisch)' : ''}',
                style: TextStyle(color: accent),
              ),
              const SizedBox(height: 8),
              const Text(
                'Der Laufweg wird anhand der aktuellen RB- '
                'und Offensive-Line-Positionen berechnet. '
                'Bestehende Blocks bleiben unverändert.',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              widget.onApply(_buildResult());
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Run anwenden'),
          ),
        ),
      ],
    );
  }
}
