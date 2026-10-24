import 'package:flutter/material.dart';

class PlayerRoute {
  PlayerRoute({required this.playerIndex, required this.points, this.name = '', this.smooth = false, this.action = 'route', this.targetIndex});
  final int playerIndex;
  final List<Offset> points; // Relative to player starting position.
  final String name;
  final bool smooth;
  final String action;
  final int? targetIndex; // Optional linked player (block or ball exchange).

  Map<String, dynamic> toJson() => {
    'playerIndex': playerIndex, 'name': name, 'smooth': smooth, 'action': action,
    'targetIndex': targetIndex,
    'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
  };

  factory PlayerRoute.fromJson(Map<String, dynamic> json) => PlayerRoute(
    playerIndex: (json['playerIndex'] as num).toInt(),
    name: json['name'] as String? ?? '',
    smooth: json['smooth'] as bool? ?? false,
    action: json['action'] as String? ?? 'route',
    targetIndex: (json['targetIndex'] as num?)?.toInt(),
    points: ((json['points'] as List?) ?? []).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return Offset((m['x'] as num).toDouble(), (m['y'] as num).toDouble());
    }).toList(),
  );
}

class RouteTemplate {
  RouteTemplate({required this.name, required this.points, this.smooth = false});
  final String name;
  final List<Offset> points;
  final bool smooth;

  Map<String, dynamic> toJson() => {
    'name': name, 'smooth': smooth,
    'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
  };
  factory RouteTemplate.fromJson(Map<String, dynamic> json) => RouteTemplate(
    name: json['name'] as String? ?? 'Eigene Route',
    smooth: json['smooth'] as bool? ?? false,
    points: ((json['points'] as List?) ?? []).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return Offset((m['x'] as num).toDouble(), (m['y'] as num).toDouble());
    }).toList(),
  );
}

// Standard templates are defined for a player on the RIGHT half of the field.
// Negative X moves inward (toward the field center); positive X moves outward.
// The editor mirrors these templates automatically for players on the left.
final standardRoutes = <RouteTemplate>[
  RouteTemplate(name: 'Go', points: [const Offset(0, 0), const Offset(0, -.35)]),
  RouteTemplate(name: 'Slant', points: [const Offset(0, 0), const Offset(0, -.08), const Offset(-.20, -.27)]),
  RouteTemplate(name: 'Post', points: [const Offset(0, 0), const Offset(0, -.20), const Offset(-.17, -.37)]),
  RouteTemplate(name: 'Corner', points: [const Offset(0, 0), const Offset(0, -.20), const Offset(.17, -.37)]),
  RouteTemplate(name: 'Out', points: [const Offset(0, 0), const Offset(0, -.20), const Offset(.22, -.20)]),
  RouteTemplate(name: 'In / Dig', points: [const Offset(0, 0), const Offset(0, -.20), const Offset(-.22, -.20)]),
  RouteTemplate(name: 'Curl', points: [const Offset(0, 0), const Offset(0, -.30), const Offset(-.04, -.22)]),
  RouteTemplate(name: 'Comeback', points: [const Offset(0, 0), const Offset(0, -.33), const Offset(.09, -.23)]),
  RouteTemplate(name: 'Drag', points: [const Offset(0, 0), const Offset(0, -.07), const Offset(-.30, -.12)]),
  RouteTemplate(name: 'Flat', points: [const Offset(0, 0), const Offset(.20, -.05)]),
  RouteTemplate(name: 'Wheel', points: [const Offset(0, 0), const Offset(.12, -.025), const Offset(.20, -.045), const Offset(.22, -.10), const Offset(.22, -.38)], smooth: true),
  RouteTemplate(name: 'Hitch', points: [const Offset(0, 0), const Offset(0, -.18), const Offset(0, -.12)]),
];
