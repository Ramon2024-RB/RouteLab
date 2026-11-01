import 'package:flutter/material.dart';

import 'run_play_designer.dart';

class BlockingAssignment {
  const BlockingAssignment({
    required this.playerIndex,
    required this.name,
    required this.points,
  });

  final int playerIndex;
  final String name;
  final List<Offset> points;
}

class BlockingDesigner {
  const BlockingDesigner._();

  static List<BlockingAssignment> generate({
    required List<Offset> positions,
    required RunConcept concept,
    required RunDirection direction,
    required RunGap gap,
  }) {
    if (positions.length < 5) {
      return const [];
    }

    // Sortieren nach Position auf dem Feld, nicht nach Spielerindex.
    // Dadurch bleiben die Blocking-Aufgaben auch bei verschobener
    // Offensive Line zur tatsächlichen Position passend.
    final line = List<int>.generate(5, (index) => index)
      ..sort((a, b) => positions[a].dx.compareTo(positions[b].dx));

    final isLeft = direction == RunDirection.left;
    final sign = isLeft ? -1.0 : 1.0;

    final center = positions[line[2]];
    final guard = positions[line[isLeft ? 1 : 3]];
    final tackle = positions[line[isLeft ? 0 : 4]];

    // Bei einem Lauf nach rechts zieht der linke Guard.
    // Bei einem Lauf nach links zieht der rechte Guard.
    final backsideGuard = line[isLeft ? 3 : 1];

    final gapX = switch (gap) {
      RunGap.a => (center.dx + guard.dx) / 2,
      RunGap.b => (guard.dx + tackle.dx) / 2,
      RunGap.c => tackle.dx + sign * .055,
      RunGap.d => tackle.dx + sign * .13,
      RunGap.auto => (center.dx + guard.dx) / 2,
    };

    final gapTarget = gapX.clamp(.05, .95).toDouble();

    final leadIndex = line.reduce((a, b) {
      final distanceA = (positions[a].dx - gapTarget).abs();
      final distanceB = (positions[b].dx - gapTarget).abs();
      return distanceA <= distanceB ? a : b;
    });

    final assignments = <BlockingAssignment>[];

    for (final playerIndex in line) {
      final origin = positions[playerIndex];

      Offset relativePoint(double x, double y) {
        return Offset(
          x.clamp(.04, .96).toDouble() - origin.dx,
          y.clamp(.04, .96).toDouble() - origin.dy,
        );
      }

      final shouldPull =
          (concept == RunConcept.power || concept == RunConcept.counter) &&
          playerIndex == backsideGuard;

      late final String name;
      late final List<Offset> points;

      if (shouldPull) {
        // Pulling Guard: zunächst hinter die Line zurück,
        // dann quer zur Playside und durch die gewählte Lücke.
        final isCounter = concept == RunConcept.counter;

        final pullDepth = isCounter ? .085 : .065;
        final pullTarget = (gapTarget + sign * .025).clamp(.05, .95).toDouble();

        name = isCounter ? 'Counter · Pulling Guard' : 'Power · Pulling Guard';

        points = [
          Offset.zero,
          relativePoint(origin.dx, origin.dy + pullDepth),
          relativePoint(
            origin.dx + (pullTarget - origin.dx) * .55,
            origin.dy + pullDepth + .02,
          ),
          relativePoint(pullTarget - sign * .025, origin.dy + .035),
          relativePoint(pullTarget, origin.dy - .10),
          relativePoint(pullTarget + sign * .025, origin.dy - .19),
        ];
      } else {
        late final double lateralFirst;
        late final double lateralFinal;
        late final double forwardFirst;
        late final double forwardFinal;

        switch (concept) {
          case RunConcept.insideZone:
            name = 'Inside Zone · Zone Block';
            lateralFirst = sign * .025;
            lateralFinal = sign * .055;
            forwardFirst = .045;
            forwardFinal = .115;

          case RunConcept.outsideZone:
            name = 'Outside Zone · Reach Block';
            lateralFirst = sign * .065;
            lateralFinal = sign * .125;
            forwardFirst = .035;
            forwardFinal = .105;

          case RunConcept.power:
            name = 'Power · Down Block';
            lateralFirst = -sign * .025;
            lateralFinal = -sign * .055;
            forwardFirst = .045;
            forwardFinal = .115;

          case RunConcept.counter:
            name = 'Counter · Down Block';
            lateralFirst = -sign * .02;
            lateralFinal = -sign * .055;
            forwardFirst = .04;
            forwardFinal = .11;

          case RunConcept.sweep:
            name = 'Sweep · Outside Seal';
            lateralFirst = sign * .08;
            lateralFinal = sign * .16;
            forwardFirst = .025;
            forwardFinal = .11;
        }

        var endX = origin.dx + lateralFinal;

        // Der dem gewählten Gap nächste Lineman kann seinen
        // Block etwas stärker in Richtung der Lücke ausrichten.
        if (playerIndex == leadIndex &&
            concept != RunConcept.power &&
            concept != RunConcept.counter) {
          endX += (gapTarget - endX) * .20;
        }

        points = [
          Offset.zero,
          relativePoint(origin.dx + lateralFirst, origin.dy - forwardFirst),
          relativePoint(endX, origin.dy - forwardFinal),
        ];
      }

      assignments.add(
        BlockingAssignment(
          playerIndex: playerIndex,
          name: name,
          points: points,
        ),
      );
    }

    return assignments;
  }
}
