import 'package:flutter/material.dart';
import '../../data/models/route_model.dart';

/// These presets are relative to the player's starting position.
/// Negative y means moving toward the opponent's end zone.
class PlayerActionPreset {
  const PlayerActionPreset(this.label, this.kind, this.points, {this.mirror = false});
  final String label;
  final String kind;
  final List<Offset> points;
  final bool mirror;
}

List<PlayerActionPreset> actionsForPlayer(int index, {bool isFullback = false}) {
  if (index == 5) {
    return const [
      PlayerActionPreset('3-Step Dropback', 'movement', [Offset.zero, Offset(0, .10)]),
      PlayerActionPreset('5-Step Dropback', 'movement', [Offset.zero, Offset(0, .16)]),
      PlayerActionPreset('7-Step Dropback', 'movement', [Offset.zero, Offset(0, .23)]),
      PlayerActionPreset('Rollout links', 'movement', [Offset.zero, Offset(-.17, .07)]),
      PlayerActionPreset('Rollout rechts', 'movement', [Offset.zero, Offset(.17, .07)]),
      PlayerActionPreset('Bootleg links', 'movement', [Offset.zero, Offset(.08, .05), Offset(-.22, .08)]),
      PlayerActionPreset('Bootleg rechts', 'movement', [Offset.zero, Offset(-.08, .05), Offset(.22, .08)]),
      PlayerActionPreset('QB Sneak', 'run', [Offset.zero, Offset(0, -.18)]),
      PlayerActionPreset('QB Draw', 'run', [Offset.zero, Offset(0, .08), Offset(0, -.23)]),
      PlayerActionPreset('Handoff', 'handoff', [Offset.zero, Offset(0, .07)]),
      PlayerActionPreset('Pass', 'pass', [Offset.zero, Offset(0, -.04)]),
      PlayerActionPreset('Pitch links', 'pitch', [Offset.zero, Offset(-.13, .04)]),
      PlayerActionPreset('Pitch rechts', 'pitch', [Offset.zero, Offset(.13, .04)]),
    ];
  }
  if (index <= 4) {
    return const [
      PlayerActionPreset('Drive Block', 'block', [Offset.zero, Offset(0, -.09)]),
      PlayerActionPreset('Reach Block innen', 'block', [Offset.zero, Offset(-.09, -.07)], mirror: true),
      PlayerActionPreset('Reach Block außen', 'block', [Offset.zero, Offset(.09, -.07)], mirror: true),
      PlayerActionPreset('Pass Protection', 'protection', [Offset.zero, Offset(0, .07)]),
      PlayerActionPreset('Pull links', 'block', [Offset.zero, Offset(0, .045), Offset(-.055, .055), Offset(-.13, .045), Offset(-.17, -.045)]),
      PlayerActionPreset('Pull rechts', 'block', [Offset.zero, Offset(0, .045), Offset(.055, .055), Offset(.13, .045), Offset(.17, -.045)]),
      PlayerActionPreset('Double Team', 'block', [Offset.zero, Offset(0, -.07)]),
    ];
  }
  if (index == 6 || (index == 10 && isFullback)) {
    return [
      ...const [
        PlayerActionPreset('Inside Zone', 'run', [Offset.zero, Offset(-.05, -.14), Offset(-.05, -.31)], mirror: true),
        PlayerActionPreset('Outside Zone', 'run', [Offset.zero, Offset(.17, -.10), Offset(.24, -.27)], mirror: true),
        PlayerActionPreset('Dive', 'run', [Offset.zero, Offset(0, -.27)]),
        PlayerActionPreset('Sweep', 'run', [Offset.zero, Offset(.20, -.06), Offset(.30, -.23)], mirror: true),
        PlayerActionPreset('Counter', 'run', [Offset.zero, Offset(-.10, -.04), Offset(.20, -.25)], mirror: true),
        PlayerActionPreset('Draw', 'run', [Offset.zero, Offset(0, .06), Offset(0, -.25)]),
        PlayerActionPreset('Lead Block', 'block', [Offset.zero, Offset(0, -.22)]),
        PlayerActionPreset('Blitz Pickup', 'protection', [Offset.zero, Offset(0, -.08)]),
        PlayerActionPreset('Flat', 'route', [Offset.zero, Offset(.18, -.06)], mirror: true),
        PlayerActionPreset('Wheel', 'route', [Offset.zero, Offset(.11, -.02), Offset(.19, -.06), Offset(.20, -.16), Offset(.20, -.36)], mirror: true),
        PlayerActionPreset('Angle / Texas', 'route', [Offset.zero, Offset(.12, -.08), Offset(-.11, -.27)], mirror: true),
        PlayerActionPreset('Swing', 'route', [Offset.zero, Offset(.20, .02), Offset(.24, -.08)], mirror: true),
        PlayerActionPreset('Checkdown', 'route', [Offset.zero, Offset(.10, -.08)], mirror: true),
        PlayerActionPreset('Screen', 'route', [Offset.zero, Offset(.17, .02), Offset(.22, -.05)], mirror: true),
      ],
    ];
  }
  if (index == 9) {
    return [
      ...standardRoutes.map((r) => PlayerActionPreset(r.name, 'route', r.points, mirror: true)),
      ...const [
        PlayerActionPreset('Drive Block', 'block', [Offset.zero, Offset(0, -.10)]),
        PlayerActionPreset('Reach Block', 'block', [Offset.zero, Offset(.09, -.08)], mirror: true),
        PlayerActionPreset('Pass Protection', 'protection', [Offset.zero, Offset(0, .07)]),
        PlayerActionPreset('Block & Release', 'block', [Offset.zero, Offset(0, -.06), Offset(.08, -.13), Offset(.10, -.26)], mirror: true),
      ],
    ];
  }
  if (index >= 11) {
    return const [
      PlayerActionPreset('Blitz', 'blitz', [Offset.zero, Offset(0, .24)]),
      PlayerActionPreset('Run Fit', 'defense', [Offset.zero, Offset(0, .15)]),
      PlayerActionPreset('Man Coverage', 'coverage', [Offset.zero, Offset(0, -.15)]),
      PlayerActionPreset('Zone Drop', 'coverage', [Offset.zero, Offset(0, -.20)]),
      PlayerActionPreset('Outside Contain', 'defense', [Offset.zero, Offset(.14, .07)], mirror: true),
    ];
  }
  return standardRoutes.map((r) => PlayerActionPreset(r.name, 'route', r.points, mirror: true)).toList();
}
