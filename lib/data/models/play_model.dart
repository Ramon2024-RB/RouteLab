import 'package:flutter/material.dart';
import 'route_model.dart';
import 'coverage_assignment.dart';

class SavedPlay {
  SavedPlay({required this.id, required this.name, required this.positions, List<PlayerRoute>? routes, List<CoverageAssignment>? coverages})
      : routes = routes ?? [], coverages = coverages ?? [];

  final String id;
  final String name;
  List<Offset> positions;
  List<PlayerRoute> routes;
  List<CoverageAssignment> coverages;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'positions': positions.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    'routes': routes.map((r) => r.toJson()).toList(),
    'coverages': coverages.map((c) => c.toJson()).toList(),
  };

  factory SavedPlay.fromJson(Map<String, dynamic> json) {
    final raw = json['positions'];
    final parsed = raw is List
        ? raw.map((entry) {
            final point = entry as Map<String, dynamic>;
            return Offset(
              (point['x'] as num).toDouble(),
              (point['y'] as num).toDouble(),
            );
          }).toList()
        : <Offset>[];
    return SavedPlay(
      id: json['id'] as String,
      name: json['name'] as String,
      positions: parsed.length == 22 ? parsed : defaultPlayerPositions(),
      coverages: ((json['coverages'] as List?) ?? [])
          .map((e) => CoverageAssignment.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((c) => c.defenderIndex >= 11 && c.defenderIndex < 22 &&
              (c.kind == 'zone' ? c.zone != null :
                  c.kind == 'man' && c.receiverIndex != null && c.receiverIndex! >= 0 && c.receiverIndex! < 11))
          .toList(),
      routes: ((json['routes'] as List?) ?? []).map((e) => PlayerRoute.fromJson(Map<String, dynamic>.from(e as Map))).where((r) => r.playerIndex >= 0 && r.playerIndex < 22).toList(),
    );
  }
}

List<Offset> defaultPlayerPositions() => [
  const Offset(.28, .62),
  const Offset(.39, .62),
  const Offset(.50, .62),
  const Offset(.61, .62),
  const Offset(.72, .62),
  const Offset(.50, .76),
  const Offset(.50, .88),
  const Offset(.12, .63),
  const Offset(.88, .63),
  const Offset(.78, .72),
  const Offset(.22, .72),
  const Offset(.28, .45),
  const Offset(.39, .45),
  const Offset(.50, .45),
  const Offset(.61, .45),
  const Offset(.72, .45),
  const Offset(.15, .35),
  const Offset(.85, .35),
  const Offset(.35, .26),
  const Offset(.65, .26),
  const Offset(.50, .15),
  const Offset(.50, .35),
];
