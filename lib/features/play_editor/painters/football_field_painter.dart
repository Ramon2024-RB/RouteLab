import 'package:flutter/material.dart';

import '../formations/offense_formations.dart';
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
      Offset(0, size.height * .54),
      Offset(size.width, size.height * .54),
      Paint()
        ..color = const Color(0xFFFFD06A)
        ..strokeWidth = 2,
    );
    if (showDefense && viewFilter != 'offense' && viewFilter != 'blocking') {
      for (final assignment in coverages) {
        if (!showAllCoverage && assignment.defenderIndex != selected) continue;
        if (focusSelected && selected != null && assignment.defenderIndex != selected &&
            assignment.receiverIndex != selected) {
          continue;
        }
        if (assignment.defenderIndex < 11 || assignment.defenderIndex >= positions.length) continue;
        final defender = positions[assignment.defenderIndex];
        final isFocused = selected == assignment.defenderIndex;
        const zoneColor = Color(0xFF7BDCC0);
        if (assignment.kind == 'zone' && assignment.zone != null) {
          final zone = assignment.zone!;
          final rect = Rect.fromLTRB(
            zone.left * size.width, zone.top * size.height,
            zone.right * size.width, zone.bottom * size.height,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(5)),
            Paint()..color = zoneColor.withValues(alpha: isFocused ? .17 : .045),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(5)),
            Paint()
              ..color = zoneColor.withValues(alpha: isFocused ? .95 : .32)
              ..style = PaintingStyle.stroke
              ..strokeWidth = isFocused ? 2.3 : 1,
          );
          // Only the selected player's assignment gets an on-field label.
          // All other player/zone pairs remain readable in Coverage-Übersicht.
          if (isFocused) {
            final positionName =
                defenseLabelsFor(defenseFormation)[assignment.defenderIndex - 11];
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
            final left = (rect.center.dx - labelWidth / 2)
                .clamp(4.0, (size.width - labelWidth - 4).clamp(4.0, size.width));
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
        } else if (showOffense && assignment.kind == 'man' && assignment.receiverIndex != null &&
            assignment.receiverIndex! >= 0 && assignment.receiverIndex! < 11) {
          final receiver = positions[assignment.receiverIndex!];
          final start = Offset(defender.dx * size.width, defender.dy * size.height);
          final end = Offset(receiver.dx * size.width, receiver.dy * size.height);
          final stroke = Paint()..color = const Color(0xFF7BDCC0)
            ..strokeWidth = isFocused ? 2.2 : 1.3 ..style = PaintingStyle.stroke;
          final delta = end - start;
          if (delta.distance > 0) {
            final unit = delta / delta.distance;
            for (var d = 0.0; d < delta.distance; d += 12) {
              canvas.drawLine(start + unit * d,
                start + unit * (d + 6).clamp(0.0, delta.distance), stroke);
            }
          }
          canvas.drawCircle(end, 20, Paint()..color = const Color(0xFF7BDCC0)
            ..style = PaintingStyle.stroke ..strokeWidth = 2);
        }
      }
    }
    for (final route in routes) {
      if (route.playerIndex < 0 || route.playerIndex >= positions.length) continue;
      if (!showDefense && route.playerIndex >= 11) continue;
      if (!showOffense && route.playerIndex < 11) continue;
      if (viewFilter == 'offense' && route.playerIndex >= 11) continue;
      if (viewFilter == 'defense' && route.playerIndex < 11) continue;
      if (viewFilter == 'blocking' &&
          route.action != 'block' && route.action != 'protection') {
        continue;
      }
      if (focusSelected && selected != null &&
          route.playerIndex != selected && route.targetIndex != selected) {
        continue;
      }
      final target = route.targetIndex;
      if (target != null && target >= 0 && target < positions.length) {
        if (!showDefense && target >= 11) continue;
        if (!showOffense && target < 11) continue;
        final start = positions[route.playerIndex];
        final end = positions[target];
        final startPixel = Offset(start.dx * size.width, start.dy * size.height);
        final endPixel = Offset(end.dx * size.width, end.dy * size.height);
        if (route.action == 'block') {
          _drawBlockAssignment(canvas, startPixel, endPixel);
        } else if (route.action == 'handoff') {
          _drawHandoff(canvas, startPixel, endPixel);
        } else {
          _drawBlockAssignment(canvas, startPixel, endPixel);
        }
      } else {
        if (route.action == 'block' || route.action == 'protection') {
          _drawBlockingTechnique(canvas, size, positions[route.playerIndex], route);
        } else {
          _drawRoute(canvas, size, positions[route.playerIndex], route.points,
              _actionColor(route.action, route.playerIndex),
              dashed: route.action == 'coverage' || route.action == 'movement');
        }
      }
    }
    if (draftPlayer != null && draftPoints.length > 1) {
      _drawRoute(canvas, size, positions[draftPlayer!], draftPoints,
          const Color(0xFFFFFF66));
    }
    for (var i = 0; i < positions.length; i++) {
      if (i >= 11 && !showDefense) continue;
      if (i < 11 && !showOffense) continue;
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
          ? offenseLabelAt(i, offenseFormation)
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

  // Classic playbook notation: a T-bar denotes a block, not a run arrow.
  // Both endpoints stop outside the player circles, keeping labels legible.
  void _drawBlockAssignment(Canvas canvas, Offset from, Offset to) {
    final delta = to - from;
    if (delta.distance < 38) return;
    final unit = delta / delta.distance;
    final side = Offset(-unit.dy, unit.dx);
    final start = from + unit * 19;
    final end = to - unit * 20;
    final paint = Paint()
      ..color = const Color(0xFFFFD166)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);
    canvas.drawLine(end - side * 9, end + side * 9, paint);
  }

  void _drawHandoff(Canvas canvas, Offset from, Offset to) {
    final delta = to - from;
    if (delta.distance < 38) return;
    final unit = delta / delta.distance;
    final start = from + unit * 18;
    final end = to - unit * 18;
    final paint = Paint()
      ..color = const Color(0xFFF2F5F0)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final length = (end - start).distance;
    for (var d = 0.0; d < length; d += 11) {
      canvas.drawLine(start + unit * d,
          start + unit * (d + 6).clamp(0.0, length), paint);
    }
    final mid = (start + end) / 2;
    canvas.drawOval(Rect.fromCenter(center: mid, width: 12, height: 7),
        Paint()..color = const Color(0xFFC98745));
  }

  void _drawBlockingTechnique(Canvas canvas, Size size, Offset origin,
      PlayerRoute route) {
    if (route.points.length < 2) return;
    Offset pixel(Offset p) => Offset((origin.dx + p.dx) * size.width,
        (origin.dy + p.dy) * size.height);
    final name = route.name.toLowerCase();
    // Pulling and block-release actions represent actual movement;
    // unlike a stationary block they keep their full drawn path.
    if (name.contains('pull') || name.contains('release') ||
        name.contains('lead')) {
      _drawRoute(canvas, size, origin, route.points,
          const Color(0xFFFFD166));
      return;
    }
    final start = pixel(route.points.first);
    final destination = pixel(route.points.last);
    final delta = destination - start;
    if (delta.distance < 1) return;
    final unit = delta / delta.distance;
    final side = Offset(-unit.dy, unit.dx);
    // Compact notation: short block stroke with a perpendicular T-cap.
    final base = start + unit * 17;
    final end = start + unit * delta.distance.clamp(29.0, 46.0);
    final paint = Paint()
      ..color = const Color(0xFFFFD166)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, end, paint);
    canvas.drawLine(end - side * 9, end + side * 9, paint);
  }

  Color _actionColor(String action, int index) => switch (action) {
    'block' || 'protection' => const Color(0xFFFFD166),
    'run' || 'movement' => const Color(0xFF57D7FF),
    'handoff' || 'pass' || 'pitch' => const Color(0xFFFFFFFF),
    'blitz' => const Color(0xFFFF6565),
    'coverage' || 'defense' => const Color(0xFFFFB35C),
    _ => index < 11 ? const Color(0xFF39F47B) : const Color(0xFFFFB35C),
  };

  void _drawRoute(Canvas canvas, Size size, Offset origin,
      List<Offset> points, Color color, {bool dashed = false}) {
    if (points.length < 2) return;
    final path = Path();
    Offset pixel(Offset p) => Offset((origin.dx + p.dx) * size.width,
        (origin.dy + p.dy) * size.height);
    path.moveTo(pixel(points.first).dx, pixel(points.first).dy);
    for (final point in points.skip(1)) {
      final next = pixel(point);
      path.lineTo(next.dx, next.dy);
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
          canvas.drawPath(metric.extractPath(distance,
              (distance + 7).clamp(0.0, metric.length)), stroke);
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
      canvas.drawPath(arrow, Paint()
        ..color = color ..strokeWidth = 3 ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant FootballFieldPainter oldDelegate) => true;
}
