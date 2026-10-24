import 'package:flutter/material.dart';

/// Coverage is a responsibility, not a movement route.
/// All coordinates are normalized to the field (0..1).
class CoverageAssignment {
  const CoverageAssignment({required this.defenderIndex, required this.kind,
    this.receiverIndex, this.zoneName, this.zone});

  final int defenderIndex; // 11..21
  final String kind; // man | zone
  final int? receiverIndex; // 0..10, only for man
  final String? zoneName;
  final Rect? zone;

  Map<String, dynamic> toJson() => {
    'defenderIndex': defenderIndex, 'kind': kind,
    'receiverIndex': receiverIndex, 'zoneName': zoneName,
    if (zone != null) 'zone': {
      'left': zone!.left, 'top': zone!.top,
      'right': zone!.right, 'bottom': zone!.bottom,
    },
  };

  factory CoverageAssignment.fromJson(Map<String, dynamic> json) {
    Rect? rect;
    final raw = json['zone'];
    if (raw is Map) {
      final z = Map<String, dynamic>.from(raw);
      rect = Rect.fromLTRB(
        (z['left'] as num).toDouble(), (z['top'] as num).toDouble(),
        (z['right'] as num).toDouble(), (z['bottom'] as num).toDouble(),
      );
    }
    return CoverageAssignment(
      defenderIndex: (json['defenderIndex'] as num).toInt(),
      kind: json['kind'] as String,
      receiverIndex: (json['receiverIndex'] as num?)?.toInt(),
      zoneName: json['zoneName'] as String?, zone: rect,
    );
  }
}

class CoverageZonePreset {
  const CoverageZonePreset(this.name, this.rect);
  final String name;
  final Rect rect;
}

const coverageZonePresets = <CoverageZonePreset>[
  CoverageZonePreset('Deep Left Third', Rect.fromLTRB(.02, .02, .34, .27)),
  CoverageZonePreset('Deep Middle Third', Rect.fromLTRB(.34, .02, .66, .27)),
  CoverageZonePreset('Deep Right Third', Rect.fromLTRB(.66, .02, .98, .27)),
  CoverageZonePreset('Deep Left Half', Rect.fromLTRB(.02, .02, .50, .27)),
  CoverageZonePreset('Deep Right Half', Rect.fromLTRB(.50, .02, .98, .27)),
  CoverageZonePreset('Deep Left Quarter', Rect.fromLTRB(.02, .02, .26, .27)),
  CoverageZonePreset('Deep Left-Middle Quarter', Rect.fromLTRB(.26, .02, .50, .27)),
  CoverageZonePreset('Deep Right-Middle Quarter', Rect.fromLTRB(.50, .02, .74, .27)),
  CoverageZonePreset('Deep Right Quarter', Rect.fromLTRB(.74, .02, .98, .27)),
  CoverageZonePreset('Left Flat', Rect.fromLTRB(.02, .30, .25, .54)),
  CoverageZonePreset('Right Flat', Rect.fromLTRB(.75, .30, .98, .54)),
  CoverageZonePreset('Left Curl/Flat', Rect.fromLTRB(.02, .28, .30, .53)),
  CoverageZonePreset('Right Curl/Flat', Rect.fromLTRB(.70, .28, .98, .53)),
  CoverageZonePreset('Left Hook/Curl', Rect.fromLTRB(.25, .28, .50, .53)),
  CoverageZonePreset('Right Hook/Curl', Rect.fromLTRB(.50, .28, .75, .53)),
  CoverageZonePreset('Middle Hook', Rect.fromLTRB(.37, .28, .63, .53)),
  CoverageZonePreset('Middle Hole', Rect.fromLTRB(.30, .18, .70, .42)),
];
