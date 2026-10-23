import 'package:flutter/material.dart';

/// Indizes 0–10 bleiben mit bestehenden gespeicherten Plays kompatibel.
const offenseLabels = <String>[
  'LT',
  'LG',
  'C',
  'RG',
  'RT',
  'QB',
  'RB',
  'WR',
  'WR',
  'TE',
  'WR',
];

const defenseLabels = <String>[
  'DE',
  'DT',
  'DT',
  'DE',
  'EDGE',
  'CB',
  'CB',
  'LB',
  'LB',
  'FS',
  'SS',
];

enum OffenseFormation { custom, shotgun, singleback, iFormation }

extension OffenseFormationName on OffenseFormation {
  String get label => switch (this) {
    OffenseFormation.custom => 'Individuell',
    OffenseFormation.shotgun => 'Shotgun',
    OffenseFormation.singleback => 'Singleback',
    OffenseFormation.iFormation => 'I-Formation',
  };
}

/// Relative Positionen: 0..1 in Breite und Höhe des Spielfelds.
/// Die fünf Linemen bleiben in jeder Formation gleich.
List<Offset> offenseFormationPositions(OffenseFormation formation) {
  const line = <Offset>[
    Offset(.30, .62),
    Offset(.40, .62),
    Offset(.50, .62),
    Offset(.60, .62),
    Offset(.70, .62),
  ];
  switch (formation) {
    case OffenseFormation.shotgun:
      return [
        ...line,
        const Offset(.50, .75), // QB
        const Offset(.63, .78), // RB
        const Offset(.09, .62), // WR
        const Offset(.91, .62), // WR
        const Offset(.79, .62), // TE
        const Offset(.18, .72), // Slot WR
      ];
    case OffenseFormation.singleback:
      return [
        ...line,
        const Offset(.50, .68),
        const Offset(.50, .84),
        const Offset(.09, .62),
        const Offset(.91, .62),
        const Offset(.79, .62),
        const Offset(.18, .70),
      ];
    case OffenseFormation.iFormation:
      return [
        ...line,
        const Offset(.50, .68),
        const Offset(.50, .88),
        const Offset(.09, .62),
        const Offset(.91, .62),
        const Offset(.79, .62),
        const Offset(.50, .78), // FB-Position (Spieler 11)
      ];
    case OffenseFormation.custom:
      throw ArgumentError('Individuell hat keine feste Aufstellung.');
  }
}

String offenseLabelAt(int index, OffenseFormation formation) {
  if (formation == OffenseFormation.iFormation && index == 10) return 'FB';
  return offenseLabels[index];
}
