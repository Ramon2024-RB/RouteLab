import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routelab/features/play_editor/formation_validator.dart';
import 'package:routelab/features/play_editor/personnel_layout.dart';
import 'package:routelab/features/play_editor/formations/offense_formations.dart';

void main() {
  const packages = <String, List<String>>{
    '10': ['RB', 'X', 'Z', 'W', 'H'],
    '11': ['RB', 'X', 'Z', 'Y', 'H'],
    '12': ['RB', 'X', 'Z', 'Y', 'U'],
    '20': ['RB', 'X', 'Z', 'HB', 'H'],
    '21': ['RB', 'X', 'Z', 'Y', 'HB'],
    '22': ['RB', 'X', 'HB', 'Y', 'U'],
  };
  const field = Size(390, 680);

  List<Offset> layout(List<String> roles, OffenseFormation formation) =>
      PersonnelLayout.arrange(
        positions: offenseFormationPositions(formation),
        roles: roles,
        formation: formation,
      );

  FormationReport validate(List<Offset> positions, List<String> roles) =>
      FormationValidator.check(
        positions: positions,
        skillRoles: roles,
        fieldSize: field,
      );

  for (final entry in packages.entries) {
    for (final formation in <OffenseFormation>[
      OffenseFormation.shotgun,
      OffenseFormation.singleback,
      OffenseFormation.iFormation,
    ]) {
      test('${entry.key} Personnel / ${formation.label}: 7 + 4', () {
        final result = validate(layout(entry.value, formation), entry.value);
        expect(result.lineCount, 7);
        expect(result.backfieldCount, 4);
        expect(
          result.errorCount,
          0,
          reason: result.issues.map((i) => i.title).join(', '),
        );
        expect(
          result.warningCount,
          0,
          reason: result.issues.map((i) => i.title).join(', '),
        );
      });
    }
  }

  test('less than seven on line is a formation error', () {
    final positions = layout(packages['12']!, OffenseFormation.shotgun);
    positions[7] = positions[7] + const Offset(0, .11); // X off line
    final result = validate(positions, packages['12']!);
    expect(result.lineCount, 6);
    expect(result.backfieldCount, 5);
    expect(result.errorCount, greaterThan(0));
  });

  test('eight on line is not by itself illegal, covered Y warns', () {
    final positions = layout(packages['12']!, OffenseFormation.shotgun);
    positions[8] = Offset(positions[8].dx, positions[9].dy); // Z covers Y
    final result = validate(positions, packages['12']!);
    expect(result.lineCount, 8);
    expect(result.backfieldCount, 3);
    expect(result.errorCount, 0);
    expect(
      result.issues.any(
        (i) => i.title.contains('Y darf hier keinen Vorwärtspass fangen'),
      ),
      isTrue,
    );
  });

  test('overlapping players generate a warning', () {
    final positions = layout(packages['11']!, OffenseFormation.shotgun);
    positions[8] = positions[7];
    final result = validate(positions, packages['11']!);
    expect(result.issues.any((i) => i.title.contains('stehen zu nah')), isTrue);
  });

  test('displaced lineman generates an error', () {
    final positions = layout(packages['21']!, OffenseFormation.singleback);
    positions[0] = positions[0] + const Offset(0, .12);
    final result = validate(positions, packages['21']!);
    expect(
      result.issues.any(
        (i) => i.title == 'Die Offensive Line steht nicht auf einer Höhe',
      ),
      isTrue,
    );
  });

  test('missing player position gives an error without crashing', () {
    final positions = layout(packages['11']!, OffenseFormation.shotgun);
    final result = validate(positions.sublist(0, 10), packages['11']!);
    expect(result.errorCount, greaterThan(0));
  });
}
