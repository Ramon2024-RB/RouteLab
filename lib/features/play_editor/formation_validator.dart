import 'dart:ui';

/// A visual, pre-snap alignment check for ordinary 11-player offense plays.
///
/// This does not model jersey numbers, unusual numbering exceptions, motion,
/// stance, or officiating judgments. It intentionally never changes positions.
enum FormationIssueLevel { error, warning }

class FormationIssue {
  const FormationIssue({
    required this.title,
    required this.detail,
    required this.level,
    this.players = const <int>[],
  });

  final String title;
  final String detail;
  final FormationIssueLevel level;
  final List<int> players;
}

class FormationReport {
  const FormationReport({
    required this.lineCount,
    required this.backfieldCount,
    required this.issues,
  });

  final int lineCount;
  final int backfieldCount;
  final List<FormationIssue> issues;

  int get errorCount =>
      issues.where((issue) => issue.level == FormationIssueLevel.error).length;

  int get warningCount => issues.length - errorCount;
  bool get isClear => issues.isEmpty;
}

class FormationValidator {
  const FormationValidator._();

  // The painter places the yellow LOS slightly ahead of the linemen's centres.
  // Compare player centres to the five OL positions, not to the yellow stroke.
  static const double _lineTolerance = .035;
  static const double _minimumPlayerSeparationPx = 27;

  static FormationReport check({
    required List<Offset> positions,
    required List<String> skillRoles,
    required Size fieldSize,
  }) {
    final issues = <FormationIssue>[];
    if (positions.length < 11 || skillRoles.length != 5) {
      issues.add(
        const FormationIssue(
          title: 'Spieler fehlen',
          detail: 'Für diesen Check braucht RouteLab 11 Offense-Spieler.',
          level: FormationIssueLevel.error,
        ),
      );
      return FormationReport(lineCount: 0, backfieldCount: 0, issues: issues);
    }

    final offense = positions.take(11).toList();
    final invalid = <int>[];
    for (var i = 0; i < offense.length; i++) {
      final p = offense[i];
      if (!p.dx.isFinite ||
          !p.dy.isFinite ||
          p.dx < 0 ||
          p.dx > 1 ||
          p.dy < 0 ||
          p.dy > 1) {
        invalid.add(i);
      }
    }
    if (invalid.isNotEmpty) {
      issues.add(
        FormationIssue(
          title: 'Ein Spieler steht außerhalb des Feldes',
          detail: 'Ziehe den Spieler zurück auf das Spielfeld.',
          level: FormationIssueLevel.error,
          players: invalid,
        ),
      );
      return FormationReport(lineCount: 0, backfieldCount: 0, issues: issues);
    }

    final lineY =
        offense.take(5).fold<double>(0, (sum, player) => sum + player.dy) / 5;
    final onLine = <int>[
      for (var i = 0; i < 11; i++)
        if ((offense[i].dy - lineY).abs() <= _lineTolerance) i,
    ];
    final backs = 11 - onLine.length;

    if (backs > 4) {
      issues.add(
        FormationIssue(
          title: 'Zu wenige Spieler an der Linie',
          detail:
              'Aktuell stehen ${onLine.length} Spieler an der Linie und '
              '$backs dahinter. Mindestens 7 müssen an der Linie stehen. '
              'Schiebe einen Spieler nach vorne.',
          level: FormationIssueLevel.error,
        ),
      );
    }

    final missingLinemen = <int>[
      for (var i = 0; i < 5; i++)
        if (!onLine.contains(i)) i,
    ];
    if (missingLinemen.isNotEmpty) {
      issues.add(
        FormationIssue(
          title: 'Die Offensive Line steht nicht auf einer Höhe',
          detail:
              'LT, LG, C, RG und RT sollten nebeneinander an der Linie '
              'stehen. Verschiebe die abweichenden Spieler.',
          level: FormationIssueLevel.error,
          players: missingLinemen,
        ),
      );
    }

    if (onLine.contains(5)) {
      issues.add(
        const FormationIssue(
          title: 'QB steht direkt an der Linie',
          detail:
              'Das ist für eine normale Aufstellung ungewöhnlich. '
              'Prüfe, ob das so geplant ist.',
          level: FormationIssueLevel.warning,
          players: <int>[5],
        ),
      );
    }

    // An eligible-numbered player on the line can only be a pass receiver
    // by position when at either end of the line. Number eligibility is
    // intentionally not assumed from the role names.
    if (onLine.length >= 2) {
      final sorted = onLine.toList()
        ..sort((a, b) => offense[a].dx.compareTo(offense[b].dx));
      final first = sorted.first;
      final last = sorted.last;
      for (var i = 6; i < 11; i++) {
        if (onLine.contains(i) && i != first && i != last) {
          final role = skillRoles[i - 6];
          issues.add(
            FormationIssue(
              title: '$role darf hier keinen Vorwärtspass fangen',
              detail:
                  '$role steht an der Linie, aber ein anderer Spieler steht '
                  'weiter außen ebenfalls an der Linie. Verschiebe $role oder '
                  'den äußeren Spieler etwas nach hinten.',
              level: FormationIssueLevel.warning,
              players: <int>[i],
            ),
          );
        }
      }
      if (first < 5 || last < 5) {
        issues.add(
          const FormationIssue(
            title: 'Ein Lineman steht ganz außen',
            detail:
                'Am äußeren Ende der Linie steht ein Offensive Lineman. '
                'Prüfe, ob das für diesen Spielzug gewollt ist.',
            level: FormationIssueLevel.warning,
          ),
        );
      }
    }

    if (fieldSize.width > 0 && fieldSize.height > 0) {
      var overlaps = 0;
      for (var a = 0; a < 11; a++) {
        for (var b = a + 1; b < 11; b++) {
          final dx = (offense[a].dx - offense[b].dx) * fieldSize.width;
          final dy = (offense[a].dy - offense[b].dy) * fieldSize.height;
          if (dx * dx + dy * dy <
              _minimumPlayerSeparationPx * _minimumPlayerSeparationPx) {
            overlaps++;
            if (overlaps <= 3) {
              String label(int index) => index < 5
                  ? const <String>['LT', 'LG', 'C', 'RG', 'RT'][index]
                  : index == 5
                  ? 'QB'
                  : skillRoles[index - 6];
              issues.add(
                FormationIssue(
                  title: '${label(a)} und ${label(b)} stehen zu nah',
                  detail:
                      'Verschiebe einen der beiden Spieler etwas, damit du '
                      'beide gut erkennen kannst.',
                  level: FormationIssueLevel.warning,
                  players: <int>[a, b],
                ),
              );
            }
          }
        }
      }
      if (overlaps > 3) {
        issues.add(
          FormationIssue(
            title: '${overlaps - 3} weitere Spielerpaare zu nah',
            detail:
                'Einige Spieler stehen sehr dicht zusammen. '
                'Ziehe sie etwas auseinander.',
            level: FormationIssueLevel.warning,
          ),
        );
      }
    }

    return FormationReport(
      lineCount: onLine.length,
      backfieldCount: backs,
      issues: issues,
    );
  }
}
