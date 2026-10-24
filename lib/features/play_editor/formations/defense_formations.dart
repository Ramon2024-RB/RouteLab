import 'package:flutter/material.dart';

/// Defense-Indizes 11–21 bleiben mit vorhandenen Plays kompatibel.
enum DefenseFormation { custom, fourThree, threeFour, nickel, dime }

extension DefenseFormationName on DefenseFormation {
  String get label => switch (this) {
    DefenseFormation.custom => 'Individuell',
    DefenseFormation.fourThree => '4-3',
    DefenseFormation.threeFour => '3-4',
    DefenseFormation.nickel => 'Nickel (4-2-5)',
    DefenseFormation.dime => 'Dime (4-1-6)',
  };
}

const _customLabels = <String>[
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

List<String> defenseLabelsFor(DefenseFormation formation) =>
    switch (formation) {
      DefenseFormation.custom => _customLabels,
      DefenseFormation.fourThree => const [
        'DE',
        'DT',
        'DT',
        'DE',
        'SLB',
        'CB',
        'CB',
        'MLB',
        'WLB',
        'FS',
        'SS',
      ],
      DefenseFormation.threeFour => const [
        'DE',
        'NT',
        'DE',
        'OLB',
        'OLB',
        'CB',
        'CB',
        'ILB',
        'ILB',
        'FS',
        'SS',
      ],
      DefenseFormation.nickel => const [
        'DE',
        'DT',
        'DT',
        'DE',
        'NB',
        'CB',
        'CB',
        'MLB',
        'WLB',
        'FS',
        'SS',
      ],
      DefenseFormation.dime => const [
        'DE',
        'DT',
        'DT',
        'DE',
        'NB',
        'CB',
        'CB',
        'LB',
        'DB',
        'FS',
        'SS',
      ],
    };

/// Koordinaten relativ zur Feldgröße, nur für die 11 Defense-Spieler.
/// Die Line of Scrimmage liegt bei y = 0.54.
List<Offset> defenseFormationPositions(DefenseFormation formation) {
  switch (formation) {
    case DefenseFormation.fourThree:
      return const [
        Offset(.30, .46),
        Offset(.43, .46),
        Offset(.57, .46),
        Offset(.70, .46),
        Offset(.22, .34),
        Offset(.10, .34),
        Offset(.90, .34),
        Offset(.50, .34),
        Offset(.78, .34),
        Offset(.50, .14),
        Offset(.70, .21),
      ];
    case DefenseFormation.threeFour:
      return const [
        Offset(.34, .46),
        Offset(.50, .46),
        Offset(.66, .46),
        Offset(.19, .39),
        Offset(.81, .39),
        Offset(.09, .33),
        Offset(.91, .33),
        Offset(.42, .32),
        Offset(.58, .32),
        Offset(.50, .14),
        Offset(.72, .20),
      ];
    case DefenseFormation.nickel:
      return const [
        Offset(.30, .46),
        Offset(.43, .46),
        Offset(.57, .46),
        Offset(.70, .46),
        Offset(.25, .25),
        Offset(.09, .34),
        Offset(.91, .34),
        Offset(.42, .32),
        Offset(.60, .32),
        Offset(.50, .13),
        Offset(.75, .20),
      ];
    case DefenseFormation.dime:
      return const [
        Offset(.30, .46),
        Offset(.43, .46),
        Offset(.57, .46),
        Offset(.70, .46),
        Offset(.24, .25),
        Offset(.09, .36),
        Offset(.91, .36),
        Offset(.50, .33),
        Offset(.76, .25),
        Offset(.43, .13),
        Offset(.62, .13),
      ];
    case DefenseFormation.custom:
      throw ArgumentError('Individuell hat keine feste Aufstellung.');
  }
}
