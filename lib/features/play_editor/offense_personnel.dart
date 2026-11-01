import 'package:flutter/material.dart';

import '../../data/models/route_model.dart';
import 'formations/offense_formations.dart';

class OffensePersonnel {
  const OffensePersonnel._();

  static const editablePlayers = <int>[6, 7, 8, 9, 10];

  static const availableRoles = <String>['X', 'Z', 'Y', 'H', 'RB', 'HB', 'FB'];

  static bool isBack(String role) {
    return role == 'RB' || role == 'HB' || role == 'FB';
  }

  static String labelAt(
    int index,
    OffenseFormation formation,
    List<PlayerRoute> routes,
  ) {
    if (index < 6 || index > 10) {
      return offenseLabelAt(index, formation);
    }

    for (final route in routes.reversed) {
      if (route.playerIndex == index &&
          route.action == 'personnel' &&
          availableRoles.contains(route.name)) {
        return route.name;
      }
    }

    return switch (index) {
      6 => 'RB',
      7 => 'X',
      8 => 'Z',
      9 => 'Y',
      10 => formation == OffenseFormation.iFormation ? 'FB' : 'H',
      _ => 'RB',
    };
  }

  static void assignRole(List<PlayerRoute> routes, int index, String role) {
    if (!editablePlayers.contains(index) || !availableRoles.contains(role)) {
      return;
    }

    routes.removeWhere(
      (route) => route.playerIndex == index && route.action == 'personnel',
    );

    routes.add(
      PlayerRoute(
        playerIndex: index,
        action: 'personnel',
        name: role,
        points: const <Offset>[],
      ),
    );
  }

  static Offset positionFor(int index, String role) {
    if (isBack(role)) {
      if (index == 6) {
        return const Offset(.50, .88);
      }

      if (role == 'FB') {
        return const Offset(.42, .82);
      }

      return switch (index) {
        7 => const Offset(.35, .88),
        8 => const Offset(.65, .88),
        9 => const Offset(.65, .86),
        10 => const Offset(.35, .86),
        _ => const Offset(.50, .88),
      };
    }

    return switch (index) {
      6 => const Offset(.12, .63),
      7 => const Offset(.12, .63),
      8 => const Offset(.88, .63),
      9 => const Offset(.78, .72),
      10 => const Offset(.22, .72),
      _ => const Offset(.50, .75),
    };
  }
}
