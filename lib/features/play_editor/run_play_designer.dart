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

enum RunDelivery { handoff, pitch }

class RunPlayResult {
  const RunPlayResult({
    required this.label,
    required this.points,
    required this.concept,
    required this.direction,
    required this.gap,
    required this.withBlocking,
    this.delivery = RunDelivery.handoff,
  });

  final String label;
  final List<Offset> points;
  final RunConcept concept;
  final RunDirection direction;
  final RunGap gap;
  final bool withBlocking;
  final RunDelivery delivery;
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
  RunDelivery delivery = RunDelivery.handoff;

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

  // V3.2 - RB route geometry

  List<Offset> _pitchRunPoints() {
    final start = widget.positions[widget.playerIndex];
    final qb = widget.positions[5];
    final side = direction == RunDirection.left ? -1.0 : 1.0;
    final left = side < 0;

    final line = widget.positions.take(5).toList()
      ..sort((a, b) => a.dx.compareTo(b.dx));

    final center = line[2];
    final guard = line[left ? 1 : 3];
    final tackle = line[left ? 0 : 4];
    final lineY = line.map((p) => p.dy).reduce((a, b) => a + b) / 5;

    final targetX = switch (effectiveGap) {
      RunGap.a => (center.dx + guard.dx) / 2,
      RunGap.b => (guard.dx + tackle.dx) / 2,
      RunGap.c => tackle.dx + side * .055,
      RunGap.d => tackle.dx + side * .13,
      RunGap.auto => tackle.dx + side * .13,
    };

    // Punkt Nummer 2 ist der gemeinsame Pitch-Fangpunkt.
    final catchPoint = _limited(qb.dx + side * .19, qb.dy + .075);

    // Erst hinter dem Slot/H-Spieler nach außen,
    // anschließend nach vorne zur Running Lane.
    final outsideX =
        (widget.positions
                    .sublist(7, 11)
                    .map((p) => p.dx)
                    .reduce(
                      (a, b) => left ? (a < b ? a : b) : (a > b ? a : b),
                    ) +
                side * .075)
            .clamp(.06, .94)
            .toDouble();
    final rearY = (catchPoint.dy + .045).clamp(.06, .94).toDouble();

    final absolute = <Offset>[
      start,
      _limited((start.dx + catchPoint.dx) / 2, (start.dy + catchPoint.dy) / 2),
      catchPoint,
      _limited((catchPoint.dx + outsideX) / 2, rearY),
      _limited(outsideX, rearY),
      _limited(outsideX, lineY + .07),
      _limited(concept == RunConcept.sweep ? outsideX : targetX, lineY - .07),
      _limited(concept == RunConcept.sweep ? outsideX : targetX, lineY - .25),
    ];

    return absolute.map((p) => p - start).toList();
  }

  RunPlayResult _buildResult() {
    final start = widget.positions[widget.playerIndex];

    final qb = widget.positions.length > 5
        ? widget.positions[5]
        : const Offset(.50, .76);

    final line = widget.positions.take(5).toList()
      ..sort((a, b) => a.dx.compareTo(b.dx));

    final sign = direction == RunDirection.left ? -1.0 : 1.0;
    final left = sign < 0;

    final center = line[2];
    final guard = line[left ? 1 : 3];
    final tackle = line[left ? 0 : 4];

    final lineY = line.map((p) => p.dy).reduce((a, b) => a + b) / line.length;

    final targetX = switch (effectiveGap) {
      RunGap.a => (center.dx + guard.dx) / 2,
      RunGap.b => (guard.dx + tackle.dx) / 2,
      RunGap.c => tackle.dx + sign * .055,
      RunGap.d => tackle.dx + sign * .13,
      RunGap.auto => (center.dx + guard.dx) / 2,
    };

    final target = targetX.clamp(.05, .95).toDouble();

    // Der RB bleibt beim Release seitlich vom QB.
    // Bereits versetzt aufgestellte RBs werden nicht
    // unnötig zurück zur Spielfeldmitte geführt.
    final qbClearX = qb.dx + sign * .115;
    final playerReleaseX = start.dx + sign * .045;

    final releaseX =
        (left
                ? (qbClearX < playerReleaseX ? qbClearX : playerReleaseX)
                : (qbClearX > playerReleaseX ? qbClearX : playerReleaseX))
            .clamp(.05, .95)
            .toDouble();

    final points = <Offset>[start];

    void normalRelease() {
      final rearX = start.dx + (releaseX - start.dx) * .55;

      points.add(_limited(rearX, start.dy - .035));

      points.add(_limited(releaseX, qb.dy + .075));
    }

    switch (concept) {
      case RunConcept.insideZone:
        normalRelease();

        points.addAll([
          _limited(releaseX, lineY + .11),
          _limited(target, lineY + .015),
          _limited(target, lineY - .13),
          _limited(target + sign * .015, lineY - .25),
        ]);

      case RunConcept.outsideZone:
        normalRelease();

        // Erst außerhalb des QB vorbeilaufen,
        // danach vor den Slot-Spielern nach außen.
        // So wird der linke/rechte WR nicht mehr
        // direkt auf Backfield-Höhe gekreuzt.
        final edge =
            (tackle.dx + sign * (effectiveGap == RunGap.d ? .16 : .105))
                .clamp(.05, .95)
                .toDouble();

        points.addAll([
          _limited(releaseX, lineY + .105),
          _limited(edge, lineY + .005),
          _limited(target, lineY - .105),
          _limited(target, lineY - .25),
        ]);

      case RunConcept.power:
        normalRelease();

        points.addAll([
          _limited(releaseX, lineY + .105),
          _limited(target, lineY + .02),
          _limited(target, lineY - .12),
          _limited(target + sign * .015, lineY - .25),
        ]);

      case RunConcept.counter:
        // Statt eines kurzen, kantigen Hakens:
        // ein sichtbarer, kleiner False Step und
        // eine fließende Gegenbewegung.
        points.addAll([
          _limited(start.dx - sign * .035, start.dy - .025),
          _limited(start.dx - sign * .025, start.dy - .075),
          _limited(releaseX, qb.dy + .015),
          _limited(releaseX, lineY + .105),
          _limited(target, lineY + .015),
          _limited(target, lineY - .12),
          _limited(target + sign * .015, lineY - .25),
        ]);

      case RunConcept.sweep:
        normalRelease();

        final edge = (tackle.dx + sign * .18).clamp(.05, .95).toDouble();

        points.addAll([
          _limited(releaseX, lineY + .11),
          _limited(edge, lineY + .01),
          _limited(edge, lineY - .12),
          _limited(edge, lineY - .25),
        ]);
    }

    // Die Daten bleiben im bestehenden relativen
    // PlayerRoute-Format gespeichert.
    final relative = points
        .map((p) => Offset(p.dx - start.dx, p.dy - start.dy))
        .toList();

    return RunPlayResult(
      label: delivery == RunDelivery.pitch
          ? 'Toss · ${concept.label} · ${direction.label} · ${effectiveGap.label}-Gap'
          : '${concept.label} · ${direction.label} · ${effectiveGap.label}-Gap',
      points: delivery == RunDelivery.pitch ? _pitchRunPoints() : relative,
      concept: concept,
      direction: direction,
      gap: effectiveGap,
      withBlocking: includeBlocking,
      delivery: delivery,
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
        const SizedBox(height: 12),
        _sectionTitle('4. Ballübergabe'),
        SegmentedButton<RunDelivery>(
          segments: const [
            ButtonSegment(value: RunDelivery.handoff, label: Text('Handoff')),
            ButtonSegment(
              value: RunDelivery.pitch,
              label: Text('Pitch / Toss'),
            ),
          ],
          selected: {delivery},
          onSelectionChanged: (value) {
            setState(() => delivery = value.first);
          },
        ),
        const SizedBox(height: 16),
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
