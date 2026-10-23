import 'package:flutter/material.dart';

class SavedPlay {
  SavedPlay({required this.id, required this.name, required this.positions});

  final String id;
  final String name;
  List<Offset> positions;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'positions': positions.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
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
