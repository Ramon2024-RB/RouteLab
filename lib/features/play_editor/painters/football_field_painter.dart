import 'package:flutter/material.dart';

import '../formations/offense_formations.dart';
import '../offense_personnel.dart';
import '../../../data/models/route_model.dart';
import '../../../data/models/coverage_assignment.dart';
import '../formations/defense_formations.dart';

class FootballFieldPainter extends CustomPainter {
  FootballFieldPainter(
    this.positions,
    this.selected,
    this.showDefense, {
    required this.offenseFormation,
    required this.defenseFormation,
    this.routes = const [],
    this.coverages = const [],
    this.showAllCoverage = true,
    this.showOffense = true,
    this.viewFilter = 'all',
    this.focusSelected = false,
    this.draftPoints = const [],
    this.draftPlayer,
  });

  final List<Offset> positions;
  final List<PlayerRoute> routes;
  final List<CoverageAssignment> coverages;
  final bool showAllCoverage;
  final bool showOffense;
  final String viewFilter;
  final bool focusSelected;
  final List<Offset> draftPoints;
  final int? draftPlayer;
  final int? selected;
  final bool showDefense;
  final OffenseFormation offenseFormation;
  final DefenseFormation defenseFormation;

  static const Color _blockColor = Color(0xFFFFD166);
  static const Color _runColor = Color(0xFF57D7FF);

  double get _scrimmageY {
    if (positions.length < 5) return .595;
    final lineY =
        positions
            .take(5)
            .fold<double>(0, (sum, position) => sum + position.dy) /
        5;
    return (lineY - .025).clamp(.04, .96).toDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      Paint()..color = const Color(0xFF145034),
    );

    final line = Paint()
      ..color = Colors.white.withValues(alpha: .28)
      ..strokeWidth = 1.2;

    for (var i = 1; i < 10; i++) {
      final y = size.height * i / 10;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }

    for (final x in [.12, .88]) {
      canvas.drawLine(
        Offset(size.width * x, 0),
        Offset(size.width * x, size.height),
        line,
      );
    }

    canvas.drawLine(
      Offset(0, size.height * _scrimmageY),
      Offset(size.width, size.height * _scrimmageY),
      Paint()
        ..color = const Color(0xFFFFD06A)
        ..strokeWidth = 2,
    );

    // Coverage-Flächen und Man Coverage bleiben unverändert.
    if (showDefense && viewFilter != 'offense' && viewFilter != 'blocking') {
      for (final assignment in coverages) {
        if (!showAllCoverage && assignment.defenderIndex != selected) {
          continue;
        }

        if (focusSelected &&
            selected != null &&
            assignment.defenderIndex != selected &&
            assignment.receiverIndex != selected) {
          continue;
        }

        if (assignment.defenderIndex < 11 ||
            assignment.defenderIndex >= positions.length) {
          continue;
        }

        final defender = positions[assignment.defenderIndex];
        final isFocused = selected == assignment.defenderIndex;
        const zoneColor = Color(0xFF7BDCC0);

        if (assignment.kind == 'zone' && assignment.zone != null) {
          final zone = assignment.zone!;

          final rect = Rect.fromLTRB(
            zone.left * size.width,
            zone.top * size.height,
            zone.right * size.width,
            zone.bottom * size.height,
          );

          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(5)),
            Paint()
              ..color = zoneColor.withValues(alpha: isFocused ? .17 : .045),
          );

          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(5)),
            Paint()
              ..color = zoneColor.withValues(alpha: isFocused ? .95 : .32)
              ..style = PaintingStyle.stroke
              ..strokeWidth = isFocused ? 2.3 : 1,
          );

          if (isFocused) {
            final positionName = defenseLabelsFor(
              defenseFormation,
            )[assignment.defenderIndex - 11];

            final shortZone = (assignment.zoneName ?? 'Zone')
                .replaceAll('Deep ', '')
                .replaceAll('Left ', 'L ')
                .replaceAll('Right ', 'R ')
                .replaceAll('Middle ', 'M ')
                .replaceAll('Third', '1/3')
                .replaceAll('Half', '1/2')
                .replaceAll('Quarter', '1/4');

            final text = TextPainter(
              text: TextSpan(
                text: '$positionName · $shortZone',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              textDirection: TextDirection.ltr,
              maxLines: 1,
              ellipsis: '…',
            )..layout(maxWidth: size.width - 16);

            final labelWidth = text.width + 16;

            final left = (rect.center.dx - labelWidth / 2).clamp(
              4.0,
              (size.width - labelWidth - 4).clamp(4.0, size.width),
            );

            final top = (rect.top + 6).clamp(4.0, size.height - 25);

            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(left, top, labelWidth, 22),
                const Radius.circular(7),
              ),
              Paint()..color = const Color(0xEE10291F),
            );

            text.paint(canvas, Offset(left + 8, top + 4));
          }
        } else if (showOffense &&
            assignment.kind == 'man' &&
            assignment.receiverIndex != null &&
            assignment.receiverIndex! >= 0 &&
            assignment.receiverIndex! < 11) {
          final receiver = positions[assignment.receiverIndex!];

          final start = Offset(
            defender.dx * size.width,
            defender.dy * size.height,
          );

          final end = Offset(
            receiver.dx * size.width,
            receiver.dy * size.height,
          );

          final stroke = Paint()
            ..color = const Color(0xFF7BDCC0)
            ..strokeWidth = isFocused ? 2.2 : 1.3
            ..style = PaintingStyle.stroke;

          final delta = end - start;

          if (delta.distance > 0) {
            final unit = delta / delta.distance;

            for (var d = 0.0; d < delta.distance; d += 12) {
              canvas.drawLine(
                start + unit * d,
                start + unit * (d + 6).clamp(0.0, delta.distance),
                stroke,
              );
            }
          }

          canvas.drawCircle(
            end,
            20,
            Paint()
              ..color = const Color(0xFF7BDCC0)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      }
    }

    // Alle Spieleraktionen zeichnen.
    for (final route in routes) {
      if (route.playerIndex < 0 || route.playerIndex >= positions.length) {
        continue;
      }

      if (!showDefense && route.playerIndex >= 11) {
        continue;
      }

      if (!showOffense && route.playerIndex < 11) {
        continue;
      }

      if (viewFilter == 'offense' && route.playerIndex >= 11) {
        continue;
      }

      if (viewFilter == 'defense' && route.playerIndex < 11) {
        continue;
      }

      if (viewFilter == 'blocking' &&
          route.action != 'block' &&
          route.action != 'protection') {
        continue;
      }

      if (focusSelected &&
          selected != null &&
          route.playerIndex != selected &&
          route.targetIndex != selected) {
        continue;
      }

      final target = route.targetIndex;

      if (target != null && target >= 0 && target < positions.length) {
        if (!showDefense && target >= 11) {
          continue;
        }

        if (!showOffense && target < 11) {
          continue;
        }

        final start = positions[route.playerIndex];
        final end = positions[target];

        final startPixel = Offset(
          start.dx * size.width,
          start.dy * size.height,
        );

        final endPixel = route.action == 'pitch' && route.points.isNotEmpty
            ? Offset(
                (start.dx + route.points.last.dx) * size.width,
                (start.dy + route.points.last.dy) * size.height,
              )
            : Offset(end.dx * size.width, end.dy * size.height);

        if (route.action == 'block') {
          _drawBlockAssignment(canvas, startPixel, endPixel);
        } else if (route.action == 'handoff' || route.action == 'pitch') {
          _drawHandoff(
            canvas,
            startPixel,
            endPixel,
            pitch: route.action == 'pitch',
          );
        } else {
          _drawBlockAssignment(canvas, startPixel, endPixel);
        }
      } else {
        final origin = positions[route.playerIndex];

        if (route.action == 'block' || route.action == 'protection') {
          _drawBlockingTechnique(canvas, size, origin, route);
        } else {
          _drawRoute(
            canvas,
            size,
            origin,
            route.points,
            _actionColor(route.action, route.playerIndex),
            dashed: route.action == 'coverage' || route.action == 'movement',
            smooth: route.smooth,
            followWaypoints:
                route.action == 'run' && route.name.startsWith('Toss · '),
          );
        }
      }
    }

    // Freihand-Entwurf.
    if (draftPlayer != null && draftPoints.length > 1) {
      _drawRoute(
        canvas,
        size,
        positions[draftPlayer!],
        draftPoints,
        const Color(0xFFFFFF66),
      );
    }

    // Spieler über den Linien zeichnen.
    for (var i = 0; i < positions.length; i++) {
      if (i >= 11 && !showDefense) {
        continue;
      }

      if (i < 11 && !showOffense) {
        continue;
      }

      final p = Offset(
        positions[i].dx * size.width,
        positions[i].dy * size.height,
      );

      if (selected == i) {
        canvas.drawCircle(p, 19, Paint()..color = Colors.white);
      }

      canvas.drawCircle(
        p,
        16,
        Paint()
          ..color = i < 11 ? const Color(0xFF238EF5) : const Color(0xFFF15C5C),
      );

      if (i >= 11 && coverages.any((c) => c.defenderIndex == i)) {
        canvas.drawCircle(
          p,
          18,
          Paint()
            ..color = const Color(0xFF7BDCC0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = selected == i ? 2.8 : 1.5,
        );
      }

      final label = i < 11
          ? OffensePersonnel.labelAt(i, offenseFormation, routes)
          : defenseLabelsFor(defenseFormation)[i - 11];

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        p - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  // Direkte Blockzuweisung zu einem Verteidiger.
  // Diese Funktion bleibt klassisch mit T-Balken.
  void _drawBlockAssignment(Canvas canvas, Offset from, Offset to) {
    final delta = to - from;

    if (delta.distance < 38) {
      return;
    }

    final unit = delta / delta.distance;
    final start = from + unit * 19;
    final end = to - unit * 20;

    final paint = Paint()
      ..color = _blockColor
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, paint);

    _drawBlockCap(canvas, end, unit, paint, width: 9);
  }

  void _drawHandoff(
    Canvas canvas,
    Offset from,
    Offset to, {
    bool pitch = false,
  }) {
    final delta = to - from;

    if (delta.distance < 38) {
      return;
    }

    final unit = delta / delta.distance;
    final start = from + unit * 18;
    final end = pitch ? to : to - unit * 18;

    final paint = Paint()
      ..color = const Color(0xFFF2F5F0)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final length = (end - start).distance;

    for (var d = 0.0; d < length; d += 11) {
      canvas.drawLine(
        start + unit * d,
        start + unit * (d + 6).clamp(0.0, length),
        paint,
      );
    }

    final mid = pitch ? to : (start + end) / 2;

    canvas.drawOval(
      Rect.fromCenter(center: mid, width: 12, height: 7),
      Paint()..color = const Color(0xFFC98745),
    );
  }

  // V2: Blocknotation nach Technik unterscheiden.
  void _drawBlockingTechnique(
    Canvas canvas,
    Size size,
    Offset origin,
    PlayerRoute route,
  ) {
    if (route.points.length < 2) return;

    final name = route.name.toLowerCase();

    if (name.contains('pull')) {
      _drawPullBlockingPath(canvas, size, origin, route.points);
      return;
    }

    if (name.contains('release') || name.contains('lead')) {
      _drawRoute(
        canvas,
        size,
        origin,
        route.points,
        _blockColor,
        smooth: route.smooth,
      );
      return;
    }

    Offset pixel(Offset p) => Offset(
      (origin.dx + p.dx) * size.width,
      (origin.dy + p.dy) * size.height,
    );

    final start = pixel(route.points.first);
    final target = pixel(route.points.last);
    final delta = target - start;

    if (delta.distance < 12) return;

    final unit = delta / delta.distance;

    final double length;
    final double capWidth;

    if (name.contains('reach')) {
      length = 39;
      capWidth = 7.5;
    } else if (name.contains('seal')) {
      length = 40;
      capWidth = 8;
    } else if (name.contains('down')) {
      length = 34;
      capWidth = 7;
    } else if (name.contains('zone')) {
      length = 35;
      capWidth = 7;
    } else if (name.contains('protection')) {
      length = 31;
      capWidth = 8;
    } else {
      length = 36;
      capWidth = 7.5;
    }

    var distance = delta.distance.clamp(22.0, length).toDouble();

    // Abstand zur gelben Line of Scrimmage halten.
    if (unit.dy < -.01) {
      final lowerLimit = size.height * _scrimmageY + 13;
      final allowed = (lowerLimit - start.dy) / unit.dy;

      if (allowed > 22 && allowed < distance) {
        distance = allowed;
      }
    }

    final from = start + unit * 17;
    final to = start + unit * distance;

    final paint = Paint()
      ..color = _blockColor
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawLine(from, to, paint);

    _drawBlockCap(canvas, to, unit, paint, width: capWidth);
  }

  void _drawPullBlockingPath(
    Canvas canvas,
    Size size,
    Offset origin,
    List<Offset> points,
  ) {
    if (points.length < 2) {
      return;
    }

    final pixels = points
        .map(
          (p) => Offset(
            (origin.dx + p.dx) * size.width,
            (origin.dy + p.dy) * size.height,
          ),
        )
        .toList();

    final path = Path()..moveTo(pixels.first.dx, pixels.first.dy);

    if (pixels.length == 2) {
      path.lineTo(pixels.last.dx, pixels.last.dy);
    } else {
      // Kurven folgen den Wegpunkten ohne scharfe Ecken.
      for (var i = 1; i < pixels.length - 1; i++) {
        final midpoint = (pixels[i] + pixels[i + 1]) / 2;

        path.quadraticBezierTo(
          pixels[i].dx,
          pixels[i].dy,
          midpoint.dx,
          midpoint.dy,
        );
      }

      path.lineTo(pixels.last.dx, pixels.last.dy);
    }

    final paint = Paint()
      ..color = _blockColor
      ..strokeWidth = 3.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);

    final end = pixels.last;
    final before = pixels[pixels.length - 2];
    final direction = end - before;

    if (direction.distance > 1) {
      _drawBlockCap(
        canvas,
        end,
        direction / direction.distance,
        paint,
        width: 10,
      );
    }
  }

  // Einheitlicher Blockbalken für alle OL-Techniken.
  void _drawBlockCap(
    Canvas canvas,
    Offset end,
    Offset direction,
    Paint paint, {
    double width = 9,
  }) {
    final side = Offset(-direction.dy, direction.dx);

    canvas.drawLine(end - side * width, end + side * width, paint);
  }

  Color _actionColor(String action, int index) => switch (action) {
    'block' || 'protection' => _blockColor,
    'run' || 'movement' => _runColor,
    'handoff' || 'pass' || 'pitch' => const Color(0xFFFFFFFF),
    'blitz' => const Color(0xFFFF6565),
    'coverage' || 'defense' => const Color(0xFFFFB35C),
    _ => index < 11 ? const Color(0xFF39F47B) : const Color(0xFFFFB35C),
  };

  // Bestehender Renderer für Passrouten und andere Bewegungen.
  void _drawRoute(
    Canvas canvas,
    Size size,
    Offset origin,
    List<Offset> points,
    Color color, {
    bool dashed = false,
    bool smooth = false,
    bool followWaypoints = false,
  }) {
    if (points.length < 2) {
      return;
    }

    final path = Path();

    Offset pixel(Offset p) => Offset(
      (origin.dx + p.dx) * size.width,
      (origin.dy + p.dy) * size.height,
    );

    final pixels = points.map(pixel).toList();

    path.moveTo(pixels.first.dx, pixels.first.dy);

    if (smooth && followWaypoints && pixels.length > 2) {
      // Kurve verläuft exakt durch alle Wegpunkte,
      // einschließlich des Pitch-Fangpunkts.
      for (var i = 0; i < pixels.length - 1; i++) {
        final p0 = pixels[i == 0 ? i : i - 1];
        final p1 = pixels[i];
        final p2 = pixels[i + 1];
        final p3 = pixels[i + 2 < pixels.length ? i + 2 : i + 1];
        final c1 = p1 + (p2 - p0) / 6;
        final c2 = p2 - (p3 - p1) / 6;
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
      }
    } else if (smooth && pixels.length > 2) {
      for (var i = 1; i < pixels.length - 1; i++) {
        final middle = (pixels[i] + pixels[i + 1]) / 2;

        path.quadraticBezierTo(
          pixels[i].dx,
          pixels[i].dy,
          middle.dx,
          middle.dy,
        );
      }

      path.lineTo(pixels.last.dx, pixels.last.dy);
    } else {
      for (final next in pixels.skip(1)) {
        path.lineTo(next.dx, next.dy);
      }
    }

    final stroke = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (dashed) {
      for (final metric in path.computeMetrics()) {
        for (var distance = 0.0; distance < metric.length; distance += 13) {
          canvas.drawPath(
            metric.extractPath(
              distance,
              (distance + 7).clamp(0.0, metric.length),
            ),
            stroke,
          );
        }
      }
    } else {
      canvas.drawPath(path, stroke);
    }

    final end = pixel(points.last);
    final before = pixel(points[points.length - 2]);
    final direction = end - before;

    if (direction.distance > 1) {
      final u = direction / direction.distance;
      final wing = Offset(-u.dy, u.dx);

      final arrow = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo((end - u * 11 + wing * 5).dx, (end - u * 11 + wing * 5).dy)
        ..moveTo(end.dx, end.dy)
        ..lineTo((end - u * 11 - wing * 5).dx, (end - u * 11 - wing * 5).dy);

      canvas.drawPath(
        arrow,
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FootballFieldPainter oldDelegate) => true;
}
