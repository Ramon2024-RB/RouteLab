import 'package:flutter/material.dart';

class FootballFieldPainter extends CustomPainter {
  FootballFieldPainter(this.positions, this.selected, this.showDefense);
  final List<Offset> positions;
  final int? selected;
  final bool showDefense;

  @override
  void paint(Canvas canvas, Size size) {
    final field = Paint()..color = const Color(0xFF145034);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      field,
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
    final scrimmage = Paint()
      ..color = const Color(0xFFFFD06A)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, size.height * .54),
      Offset(size.width, size.height * .54),
      scrimmage,
    );
    for (var i = 0; i < positions.length; i++) {
      if (i >= 11 && !showDefense) continue;
      final p = Offset(
        positions[i].dx * size.width,
        positions[i].dy * size.height,
      );
      final selectedPaint = Paint()..color = Colors.white;
      final player = Paint()
        ..color = i < 11 ? const Color(0xFF238EF5) : const Color(0xFFF15C5C);
      if (selected == i) canvas.drawCircle(p, 16, selectedPaint);
      canvas.drawCircle(p, 12, player);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i < 11 ? i + 1 : i - 10}',
          style: const TextStyle(
            fontSize: 10,
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

  @override
  bool shouldRepaint(covariant FootballFieldPainter oldDelegate) => true;
}
