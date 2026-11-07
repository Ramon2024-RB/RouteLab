import 'package:flutter/material.dart';

import 'formations/offense_formations.dart';

/// 11-man offense: five linemen plus TWO ends on the line;
/// the quarterback and remaining skill players are behind the line.
/// Role and alignment remain independent (e.g. U may be off-line).
class PersonnelLayout {
  const PersonnelLayout._();

  static bool _isBack(String role) =>
      role == 'RB' || role == 'HB' || role == 'FB';

  static List<Offset> arrange({
    required List<Offset> positions,
    required List<String> roles,
    required OffenseFormation formation,
  }) {
    if (positions.length < 11 || roles.length != 5) {
      throw ArgumentError('11 Spieler und fuenf Skill-Rollen erforderlich.');
    }

    final result = List<Offset>.from(positions);
    final lineY =
        positions
            .take(5)
            .fold<double>(0, (sum, position) => sum + position.dy) /
        5;
    final leftTackle = positions
        .take(5)
        .fold<double>(
          1,
          (minX, position) => position.dx < minX ? position.dx : minX,
        );
    final rightTackle = positions
        .take(5)
        .fold<double>(
          0,
          (maxX, position) => position.dx > maxX ? position.dx : maxX,
        );
    final centerX = positions[2].dx;
    final qbY = positions[5].dy;

    Offset point(double x, double y) =>
        Offset(x.clamp(.045, .955).toDouble(), y.clamp(.05, .94).toDouble());

    // Exactly two eligible ends are placed on the line. For standard
    // packages: 10/20 = X + Z; 11/12/21 = X + Y; 22 = U + Y.
    // Off-line receivers and the remaining TE(s) stay in the backfield.
    final leftEnd =
        roles.contains('U') && roles.contains('Y') && !roles.contains('Z')
        ? 'U'
        : roles.contains('X')
        ? 'X'
        : roles.contains('U')
        ? 'U'
        : roles.firstWhere((r) => !_isBack(r), orElse: () => '');
    final rightEnd = roles.contains('Y') && leftEnd != 'Y'
        ? 'Y'
        : roles.contains('Z') && leftEnd != 'Z'
        ? 'Z'
        : roles.firstWhere(
            (r) => !_isBack(r) && r != leftEnd,
            orElse: () => '',
          );

    if (leftEnd.isEmpty || rightEnd.isEmpty || leftEnd == rightEnd) {
      throw ArgumentError('Zwei unterschiedliche End-Spieler erforderlich.');
    }

    for (var slot = 0; slot < roles.length; slot++) {
      final index = slot + 6;
      final role = roles[slot];
      if (_isBack(role)) continue;

      if (role == leftEnd) {
        result[index] = point(
          role == 'U' || role == 'Y' ? leftTackle - .095 : leftTackle - .20,
          lineY,
        );
      } else if (role == rightEnd) {
        result[index] = point(
          role == 'Y' || role == 'U' ? rightTackle + .095 : rightTackle + .20,
          lineY,
        );
      } else {
        result[index] = switch (role) {
          'X' => point(leftTackle - .20, lineY + .12),
          'Z' => point(rightTackle + .20, lineY + .12),
          'U' => point(leftTackle - .12, lineY + .12),
          'Y' => point(rightTackle + .12, lineY + .12),
          'H' => point(leftTackle - .12, lineY + .13),
          'W' => point(rightTackle + .12, lineY + .13),
          _ => point(centerX, lineY + .13),
        };
      }
    }

    final backs =
        <int>[
          for (var i = 0; i < roles.length; i++)
            if (_isBack(roles[i])) i + 6,
        ]..sort((a, b) {
          int rank(String role) => switch (role) {
            'RB' => 0,
            'HB' => 1,
            'FB' => 2,
            _ => 3,
          };
          return rank(roles[a - 6]).compareTo(rank(roles[b - 6]));
        });

    if (backs.length == 1) {
      final x = formation == OffenseFormation.shotgun ? centerX + .14 : centerX;
      final y = formation == OffenseFormation.shotgun
          ? qbY + .035
          : formation == OffenseFormation.iFormation
          ? qbY + .20
          : qbY + .16;
      result[backs.first] = point(x, y);
    } else if (backs.length == 2) {
      if (formation == OffenseFormation.iFormation) {
        result[backs[0]] = point(centerX, qbY + .20);
        result[backs[1]] = point(centerX, qbY + .10);
      } else if (formation == OffenseFormation.shotgun) {
        result[backs[0]] = point(centerX + .14, qbY + .035);
        result[backs[1]] = point(centerX - .14, qbY + .035);
      } else {
        result[backs[0]] = point(centerX + .11, qbY + .16);
        result[backs[1]] = point(centerX - .11, qbY + .12);
      }
    } else if (backs.length > 2) {
      for (var i = 0; i < backs.length; i++) {
        final x = centerX + (i - (backs.length - 1) / 2) * .16;
        result[backs[i]] = point(x, qbY + .13);
      }
    }

    return result;
  }
}
