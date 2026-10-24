import 'package:flutter/material.dart';
import '../../data/models/route_model.dart';
import '../../data/models/coverage_assignment.dart';
import '../../data/repositories/route_repository.dart';

import 'formations/offense_formations.dart';
import 'formations/defense_formations.dart';
import 'painters/football_field_painter.dart';
import 'player_actions.dart';

class PlayEditor extends StatefulWidget {
  const PlayEditor({
    super.key,
    required this.title,
    required this.initialPositions,
    required this.onPositionsChanged,
    required this.initialRoutes,
    required this.onRoutesChanged,
    required this.initialCoverages,
    required this.onCoveragesChanged,
  });

  final List<PlayerRoute> initialRoutes;
  final void Function(List<PlayerRoute> updated) onRoutesChanged;
  final List<CoverageAssignment> initialCoverages;
  final void Function(List<CoverageAssignment> updated) onCoveragesChanged;
  final String title;
  final List<Offset> initialPositions;
  final ValueChanged<List<Offset>> onPositionsChanged;

  @override
  State<PlayEditor> createState() => _PlayEditorState();
}

class _PlayEditorState extends State<PlayEditor> {
  late final List<Offset> positions;
  OffenseFormation formation = OffenseFormation.custom;
  DefenseFormation defenseFormation = DefenseFormation.custom;
  int? selected;
  bool showDefense = true;
  bool routeMode = false;
  bool freehand = true;
  bool formationsExpanded = false;
  String viewFilter = 'all';
  bool focusSelected = false;
  bool toolsExpanded = false;
  String drawingAction = 'route';
  String? targetMode; // 'block' or 'handoff' while selecting another player.
  final List<Offset> draft = [];
  late final List<PlayerRoute> routes;
  late final List<CoverageAssignment> coverages;
  bool showAllCoverage = true;
  int? zoneSelectionPlayer;
  String zoneSelectionGroup = 'Deep Third';
  final List<RouteTemplate> templates = [];
  final RouteStorage routeStorage = RouteStorage();

  @override
  void initState() {
    super.initState();
    positions = List<Offset>.from(widget.initialPositions);
    routes = List<PlayerRoute>.from(widget.initialRoutes);
    coverages = List<CoverageAssignment>.from(widget.initialCoverages);
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final saved = await routeStorage.load();
      if (mounted) setState(() => templates.addAll(saved));
    } catch (e) {
      _message('Routenvorlagen konnten nicht geladen werden: $e');
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  void _saveCoverages() => widget.onCoveragesChanged(List<CoverageAssignment>.from(coverages));

  void _saveRoutes() => widget.onRoutesChanged(List<PlayerRoute>.from(routes));

  Offset _relative(Offset pixel, Size size, int player) => Offset(
    (pixel.dx / size.width - positions[player].dx).clamp(-1.0, 1.0),
    (pixel.dy / size.height - positions[player].dy).clamp(-1.0, 1.0),
  );

  void _beginDraw(Offset pixel, Size size) {
    // A single gesture may start on the player and continue into a route.
    // Previously the first gesture only selected the player, so drawing
    // appeared to be broken until a second attempt.
    if (selected == null) {
      selectAt(pixel, size);
    }
    if (selected == null || !freehand) return;
    setState(() {
      draft.clear();
      draft.add(Offset.zero);
      final point = _relative(pixel, size, selected!);
      if (point.distance > .025) draft.add(point);
    });
  }

  void _drawMove(Offset pixel, Size size) {
    if (selected == null || !freehand || draft.isEmpty) return;
    final point = _relative(pixel, size, selected!);
    final last = draft.last;
    if ((Offset((point.dx-last.dx)*size.width,
        (point.dy-last.dy)*size.height)).distance < 4) {
      return;
    }
    setState(() => draft.add(point));
  }

  void _finishDraw() {
    if (selected == null || draft.length < 2) return;
    setState(() {
      routes.removeWhere((r) => r.playerIndex == selected && r.action == drawingAction);
      routes.add(PlayerRoute(playerIndex: selected!, points: List.of(draft), smooth: freehand, action: drawingAction));
      draft.clear();
    });
    _saveRoutes();
  }

  void _tapRoute(Offset pixel, Size size) {
    if (selected == null) {
      selectAt(pixel, size);
      return;
    }
    setState(() {
      if (draft.isEmpty) draft.add(Offset.zero);
      draft.add(_relative(pixel, size, selected!));
    });
  }

  void _applyRoute(RouteTemplate template) {
    if (selected == null) return;
    // Only built-in routes are auto-mirrored. User-created templates retain
    // the exact direction in which they were originally drawn.
    final isStandard = standardRoutes.contains(template);
    final mirror = isStandard && positions[selected!].dx < .5;
    final mirrored = template.points.map((point) =>
        Offset(mirror ? -point.dx : point.dx, point.dy)).toList();
    // Keep routes on the field, especially outward-breaking routes from
    // receivers positioned near a sideline. Scale X only, not Y: a Wheel
    // must still turn UPFIELD after the initial Flat release.
    final originX = positions[selected!].dx;
    final maxRight = mirrored.fold<double>(0, (m, p) => p.dx > m ? p.dx : m);
    final maxLeft = mirrored.fold<double>(0, (m, p) => -p.dx > m ? -p.dx : m);
    var xScale = 1.0;
    if (maxRight > 0) {
      xScale = (xScale < (.96 - originX) / maxRight)
        ? xScale : (.96 - originX) / maxRight;
    }
    if (maxLeft > 0) {
      xScale = (xScale < (originX - .04) / maxLeft)
        ? xScale : (originX - .04) / maxLeft;
    }
    xScale = xScale.clamp(.15, 1.0);
    final appliedPoints = mirrored.map((p) => Offset(p.dx * xScale, p.dy)).toList();
    setState(() {
      routes.removeWhere((r) => r.playerIndex == selected && r.action == 'route');
      routes.add(PlayerRoute(playerIndex: selected!, points: appliedPoints,
          name: template.name, smooth: template.smooth));
      draft.clear();
    });
    _saveRoutes();
  }

  Future<void> _showPlayerActions() async {
    if (selected == null) {
      _message('Wähle zuerst einen Spieler aus.');
      return;
    }
    final player = selected!;
    if (player >= 11) { await _showCoverageActions(player); return; }
    final presets = actionsForPlayer(player, isFullback: formation == OffenseFormation.iFormation);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .64,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Aktionen für ${player < 11 ? offenseLabelAt(player, formation) : defenseLabelsFor(defenseFormation)[player - 11]}',
                  style: Theme.of(ctx).textTheme.titleLarge),
            ),
            Expanded(child: ListView.builder(
              itemCount: presets.length,
              itemBuilder: (ctx, index) {
                final preset = presets[index];
                return ListTile(
                  title: Text(preset.label),
                  subtitle: Text(preset.kind),
                  leading: const Icon(Icons.alt_route),
                  onTap: () {
                    final mirror = preset.mirror && positions[player].dx < .5;
                    final points = preset.points.map((p) => Offset(mirror ? -p.dx : p.dx, p.dy)).toList();
                    final origin = positions[player];
                    final maxX = points.fold<double>(0, (m, p) => p.dx > m ? p.dx : m);
                    final minX = points.fold<double>(0, (m, p) => -p.dx > m ? -p.dx : m);
                    var scale = 1.0;
                    if (maxX > 0) scale = scale.clamp(0.0, (.97 - origin.dx) / maxX).toDouble();
                    if (minX > 0) scale = scale.clamp(0.0, (origin.dx - .03) / minX).toDouble();
                    setState(() {
                      routes.removeWhere((r) => r.playerIndex == player && r.action == preset.kind);
                      routes.add(PlayerRoute(
                        playerIndex: player,
                        name: preset.label,
                        action: preset.kind,
                        points: points.map((p) => Offset(p.dx * scale, p.dy)).toList(),
                      ));
                      draft.clear();
                    });
                    _saveRoutes();
                    Navigator.pop(ctx);
                  },
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  Future<void> _showCoverageActions(int player) async {
    await showModalBottomSheet<void>(context: context, builder: (ctx) =>
      SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: Text('Defense: ${defenseLabelsFor(defenseFormation)[player - 11]}'),
          subtitle: const Text('Coverage als echte Spieleraufgabe speichern')),
        ListTile(leading: const Icon(Icons.person_search), title: const Text('Man Coverage zuweisen'),
          subtitle: const Text('Danach den Gegenspieler auf dem Feld antippen'),
          onTap: () { Navigator.pop(ctx); setState(() { targetMode = 'man'; routeMode = false; toolsExpanded = false; });
            _message('Jetzt den zu deckenden Offense-Spieler antippen.'); }),
        ListTile(leading: const Icon(Icons.layers_outlined), title: const Text('Zone Coverage zuweisen'),
          subtitle: const Text('Zonenbereich auswählen und speichern'),
          onTap: () { Navigator.pop(ctx); _chooseCoverageZone(player); }),
        ListTile(leading: const Icon(Icons.directions_run), title: const Text('Blitz / Run Fit'),
          onTap: () { Navigator.pop(ctx); _showDefenseMovementActions(player); }),
        if (coverages.any((c) => c.defenderIndex == player))
          ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Coverage-Aufgabe entfernen'),
            onTap: () { Navigator.pop(ctx); setState(() => coverages.removeWhere((c) => c.defenderIndex == player)); _saveCoverages(); }),
      ])),
    );
  }

  Future<void> _showDefenseMovementActions(int player) async {
    final presets = actionsForPlayer(player).where((a) => a.kind != 'coverage').toList();
    await showModalBottomSheet<void>(context: context, builder: (ctx) =>
      SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: presets.map((preset) =>
        ListTile(title: Text(preset.label), onTap: () {
          setState(() {
            routes.removeWhere((r) => r.playerIndex == player && r.action == preset.kind);
            routes.add(PlayerRoute(playerIndex: player, action: preset.kind,
              name: preset.label, points: preset.points));
          });
          _saveRoutes(); Navigator.pop(ctx);
        }),
      ).toList())),
    );
  }

  void _chooseCoverageZone(int player) {
    setState(() {
      zoneSelectionPlayer = player;
      zoneSelectionGroup = 'Deep Third';
      routeMode = false;
      targetMode = null;
      toolsExpanded = false;
      showAllCoverage = true;
    });
  }

  List<CoverageZonePreset> get _visibleZonePresets {
    switch (zoneSelectionGroup) {
      case 'Deep Half':
        return coverageZonePresets.where((z) => z.name.contains('Half')).toList();
      case 'Deep Quarter':
        return coverageZonePresets.where((z) => z.name.contains('Quarter')).toList();
      case 'Underneath':
        return coverageZonePresets.where((z) =>
          !z.name.contains('Deep')).toList();
      default:
        return coverageZonePresets.where((z) => z.name.contains('Third')).toList();
    }
  }

  void _assignCoverageZone(CoverageZonePreset preset) {
    final player = zoneSelectionPlayer;
    if (player == null) return;
    setState(() {
      coverages.removeWhere((c) => c.defenderIndex == player);
      coverages.add(CoverageAssignment(
        defenderIndex: player,
        kind: 'zone',
        zoneName: preset.name,
        zone: preset.rect,
      ));
      zoneSelectionPlayer = null;
      showAllCoverage = true;
    });
    _saveCoverages();
    _message('${preset.name} zugewiesen.');
  }

  Widget _zoneSelectionOverlay(Size fieldSize) {
    final player = zoneSelectionPlayer;
    if (player == null) return const SizedBox.shrink();
    final presets = _visibleZonePresets;
    return Stack(children: [
      ...presets.map((preset) {
        final r = preset.rect;
        return Positioned(
          left: r.left * fieldSize.width,
          top: r.top * fieldSize.height,
          width: r.width * fieldSize.width,
          height: r.height * fieldSize.height,
          child: Material(
            color: Colors.lightBlueAccent.withValues(alpha: .25),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.lightBlueAccent, width: 1.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: InkWell(
              onTap: () => _assignCoverageZone(preset),
              child: Center(child: Padding(
                padding: const EdgeInsets.all(3),
                child: Text(preset.name.replaceAll('Deep ', ''),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white,
                    fontSize: 11, fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 5)])),
              )),
            ),
          ),
        );
      }),
      Positioned(left: 6, right: 6, bottom: 8,
        child: Material(
          color: const Color(0xEE102219),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Zone für ${defenseLabelsFor(defenseFormation)[player - 11]} antippen',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SingleChildScrollView(scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final group in const ['Deep Third', 'Deep Half', 'Deep Quarter', 'Underneath'])
                    Padding(padding: const EdgeInsets.only(right: 5),
                      child: ChoiceChip(
                        label: Text(group, style: const TextStyle(fontSize: 10)),
                        visualDensity: VisualDensity.compact,
                        selected: zoneSelectionGroup == group,
                        onSelected: (_) => setState(() => zoneSelectionGroup = group),
                      )),
                  IconButton(
                    tooltip: 'Abbrechen',
                    onPressed: () => setState(() => zoneSelectionPlayer = null),
                    icon: const Icon(Icons.close, size: 19),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }

  void _startTargetAssignment(String kind) {
    if (selected == null) {
      _message('Wähle zuerst einen Spieler aus.');
      return;
    }
    final player = selected!;
    if (player >= 11) {
      _message('Wähle einen Offense-Spieler.');
      return;
    }
    if (kind == 'handoff' && player != 5) {
      _message('Für die Übergabe zuerst den QB auswählen.');
      return;
    }
    setState(() {
      targetMode = kind;
      routeMode = false;
      draft.clear();
    });
    _message(kind == 'block'
        ? 'Tippe auf den Verteidiger, der geblockt werden soll.'
        : 'Tippe auf den RB oder einen anderen Offense-Spieler als Ballempfänger.');
  }

  void _assignTarget(int? target) {
    final source = selected;
    final kind = targetMode;
    if (source == null || kind == null) return;
    if (target == null) {
      _message('Tippe direkt auf den gewünschten Spieler.');
      return;
    }
    if (kind == 'man') {
      if (source < 11 || target >= 11) {
        _message('Für Man Coverage einen Offense-Spieler auswählen.'); return;
      }
      setState(() {
        coverages.removeWhere((c) => c.defenderIndex == source);
        coverages.add(CoverageAssignment(defenderIndex: source, kind: 'man', receiverIndex: target));
        targetMode = null; showAllCoverage = true;
      });
      _saveCoverages(); return;
    }
    if (kind == 'block' && target < 11) {
      _message('Ein Blockziel muss ein Defense-Spieler sein.');
      return;
    }
    if (kind == 'handoff' && (target >= 11 || target == source)) {
      _message('Wähle einen anderen Offense-Spieler für die Übergabe.');
      return;
    }
    final origin = positions[source];
    final destination = positions[target];
    setState(() {
      routes.removeWhere((r) => r.playerIndex == source && r.action == kind);
      routes.add(PlayerRoute(
        playerIndex: source,
        action: kind,
        targetIndex: target,
        name: kind == 'block' ? 'Blockziel' : 'Handoff',
        points: [Offset.zero, destination - origin],
      ));
      targetMode = null;
    });
    _saveRoutes();
  }

  int? _playerAt(Offset point, Size size) {
    int? closest;
    var distanceLimit = 28.0;
    for (var i = 0; i < positions.length; i++) {
      if (!showDefense && i >= 11) continue;
      final pixel = Offset(positions[i].dx * size.width, positions[i].dy * size.height);
      final distance = (pixel - point).distance;
      if (distance < distanceLimit) {
        distanceLimit = distance;
        closest = i;
      }
    }
    return closest;
  }

  void _undoLastAction() {
    if (selected == null) return;
    final index = routes.lastIndexWhere((r) => r.playerIndex == selected);
    if (index < 0) return;
    setState(() => routes.removeAt(index));
    _saveRoutes();
  }

  Future<void> _saveTemplate() async {
    if (selected == null) return;
    final existing = routes.where((r) => r.playerIndex == selected).toList();
    final points = draft.length >= 2 ? List<Offset>.from(draft)
        : existing.isNotEmpty ? List<Offset>.from(existing.last.points) : <Offset>[];
    if (points.length < 2) {
      _message('Zeichne zuerst eine Route.');
      return;
    }
    final controller = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Route als Vorlage speichern'),
      content: TextField(controller: controller, autofocus: true,
          decoration: const InputDecoration(labelText: 'Routenname')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Speichern'))],
    ));
    controller.dispose();
    if (!mounted || name == null || name.isEmpty) return;
    setState(() => templates.add(RouteTemplate(name: name, points: points, smooth: freehand)));
    try {
      await routeStorage.save(templates);
      _message('„$name“ wurde in Meine Routen gespeichert.');
    } catch (e) { _message('Vorlage konnte nicht gespeichert werden: $e'); }
  }

  Future<void> _showRouteLibrary() async {
    if (selected == null) { _message('Wähle zuerst einen Spieler aus.'); return; }
    await showModalBottomSheet<void>(context: context, isScrollControlled: true,
      builder: (ctx) => SafeArea(child: SizedBox(height: MediaQuery.sizeOf(ctx).height * .65,
        child: DefaultTabController(length: 2, child: Column(children: [
          const TabBar(tabs: [Tab(text: 'Standardrouten'), Tab(text: 'Meine Routen')]),
          Expanded(child: TabBarView(children: [
            _routeList(ctx, _routesForSelected()), _routeList(ctx, templates),
          ])),
        ])),
      )),
    );
  }

  List<RouteTemplate> _routesForSelected() {
    if (selected == null) return standardRoutes;
    final i = selected!;
    if (i >= 11 || i <= 4 || i == 5) return [];
    if (i == 6 || (formation == OffenseFormation.iFormation && i == 10)) {
      const names = {'Flat', 'Wheel', 'Drag', 'Slant', 'Angle / Texas', 'Swing', 'Checkdown', 'Screen'};
      return standardRoutes.where((r) => names.contains(r.name)).toList();
    }
    return standardRoutes;
  }

  Widget _routeList(BuildContext sheetContext, List<RouteTemplate> entries) {
    if (entries.isEmpty) return const Center(child: Text('Noch keine eigenen Routen gespeichert.'));
    return ListView.builder(itemCount: entries.length, itemBuilder: (ctx, index) {
      final route = entries[index];
      return ListTile(
        leading: const Icon(Icons.alt_route, color: Color(0xFF39F47B)),
        title: Text(route.name),
        subtitle: Text('${route.points.length} Punkte'),
        trailing: const Icon(Icons.add_circle_outline),
        onTap: () { _applyRoute(route); Navigator.pop(sheetContext); },
      );
    });
  }

  void _deleteSelectedRoute() {
    if (selected == null) return;
    final player = selected!;
    final hasRoute = routes.any((r) => r.playerIndex == player && r.action == 'route');
    if (!hasRoute) return;
    setState(() {
      routes.removeWhere((r) => r.playerIndex == player && r.action == 'route');
      draft.clear();
    });
    _saveRoutes();
    _message('Passroute entfernt. Andere Spieleraktionen bleiben erhalten.');
  }

  void _savePositions() =>
      widget.onPositionsChanged(List<Offset>.from(positions));

  void _applyFormation(OffenseFormation next) {
    if (next == OffenseFormation.custom) {
      return;
    }
    final preset = offenseFormationPositions(next);
    setState(() {
      for (var i = 0; i < 11; i++) {
        positions[i] = preset[i];
      }
      formation = next;
      selected = null;
      draft.clear();
    });
    _savePositions();
  }

  void _applyDefenseFormation(DefenseFormation next) {
    if (next == DefenseFormation.custom) {
      return;
    }
    final preset = defenseFormationPositions(next);
    setState(() {
      for (var i = 0; i < 11; i++) {
        positions[i + 11] = preset[i];
      }
      defenseFormation = next;
      selected = null;
      draft.clear();
    });
    _savePositions();
  }

  String get _selectedLabel {
    if (selected == null) return 'Spieler auswählen';
    if (selected! < 11) return offenseLabelAt(selected!, formation);
    return defenseLabelsFor(defenseFormation)[selected! - 11];
  }

  Widget _field() => LayoutBuilder(builder: (context, constraints) {
    final fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
    return Stack(fit: StackFit.expand, children: [GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        if (targetMode != null || zoneSelectionPlayer != null) return;
        if (routeMode) { _beginDraw(details.localPosition, fieldSize); }
        else { selectAt(details.localPosition, fieldSize); }
      },
      onPanUpdate: (details) {
        if (targetMode != null || zoneSelectionPlayer != null) return;
        if (routeMode) { _drawMove(details.localPosition, fieldSize); return; }
        if (selected == null) return;
        setState(() {
          positions[selected!] = Offset(
            (details.localPosition.dx / fieldSize.width).clamp(.03, .97),
            (details.localPosition.dy / fieldSize.height).clamp(.03, .97),
          );
          if (selected! < 11) { formation = OffenseFormation.custom; }
          else { defenseFormation = DefenseFormation.custom; }
        });
      },
      onPanEnd: (_) {
        if (targetMode != null || zoneSelectionPlayer != null) return;
        if (routeMode) { if (freehand) { _finishDraw(); } }
        else { _savePositions(); }
      },
      onPanCancel: () {
        if (targetMode != null || zoneSelectionPlayer != null) return;
        if (routeMode) { setState(() => draft.clear()); }
        else { _savePositions(); }
      },
      onTapUp: (details) {
        if (zoneSelectionPlayer != null) return;
        if (targetMode != null) {
          _assignTarget(_playerAt(details.localPosition, fieldSize));
          return;
        }
        if (routeMode) {
          if (!freehand) {
            if (selected == null) { selectAt(details.localPosition, fieldSize); }
            else { _tapRoute(details.localPosition, fieldSize); }
          } else {
            final previous = selected;
            selectAt(details.localPosition, fieldSize);
            if (selected == null && previous != null) {
              setState(() => selected = previous);
            }
          }
        } else { selectAt(details.localPosition, fieldSize); }
      },
      child: CustomPaint(
        size: Size.infinite,
        painter: FootballFieldPainter(
          positions, selected, showDefense,
          offenseFormation: formation,
          defenseFormation: defenseFormation,
          routes: routes,
          coverages: coverages,
          showAllCoverage: showAllCoverage,
          viewFilter: viewFilter,
          focusSelected: focusSelected,
          draftPoints: draft,
          draftPlayer: selected,
        ),
      ),
    ),
    if (zoneSelectionPlayer != null) _zoneSelectionOverlay(fieldSize),
    ]);
  });

  Widget _toolButton(IconData icon, String label, VoidCallback? onTap, {bool active = false}) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: active ? accent.withValues(alpha: .17) : Colors.white.withValues(alpha: .055),
          border: Border.all(color: active ? accent.withValues(alpha: .5) : Colors.white12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? accent : Colors.white70, size: 21),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11), maxLines: 1),
        ]),
      ),
    );
  }

  Widget _formationsPanel() => Column(children: [
    DropdownButtonFormField<OffenseFormation>(
      key: ValueKey('offense_$formation'), initialValue: formation,
      decoration: const InputDecoration(labelText: 'Offense', border: OutlineInputBorder(), isDense: true),
      items: OffenseFormation.values.map((v) => DropdownMenuItem(value: v, child: Text(v.label))).toList(),
      onChanged: (v) { if (v != null) { _applyFormation(v); } },
    ),
    const SizedBox(height: 10),
    DropdownButtonFormField<DefenseFormation>(
      key: ValueKey('defense_$defenseFormation'), initialValue: defenseFormation,
      decoration: const InputDecoration(labelText: 'Defense', border: OutlineInputBorder(), isDense: true),
      items: DefenseFormation.values.map((v) => DropdownMenuItem(value: v, child: Text(v.label))).toList(),
      onChanged: (v) { if (v != null) { _applyDefenseFormation(v); } },
    ),
  ]);

  Future<void> _openFormations() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 8, 18,
              MediaQuery.viewInsetsOf(ctx).bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Formationen', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 20),
            _formationsPanel(),
          ]),
        ),
      ),
    );
  }

  Widget _compactControls() {
    final accent = Theme.of(context).colorScheme.primary;
    final count = selected == null ? 0 :
        routes.where((r) => r.playerIndex == selected).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF102219),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(children: [
        CircleAvatar(radius: 16,
          backgroundColor: selected == null ? Colors.white12 :
              selected! < 11 ? const Color(0xFF238EE8) : const Color(0xFFF25D63),
          child: const Icon(Icons.person_outline, size: 18, color: Colors.white)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, children: [
          Text(_selectedLabel, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(selected == null ? 'Spieler antippen' : '$count Routen · ${coverages.where((c) => c.defenderIndex == selected).length} Coverage',
            style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ])),
        PopupMenuButton<String>(
          tooltip: 'Ansicht filtern',
          icon: const Icon(Icons.filter_alt_outlined),
          onSelected: (v) => setState(() => viewFilter = v),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'all', child: Text('Alle Aktionen')),
            PopupMenuItem(value: 'offense', child: Text('Offense')),
            PopupMenuItem(value: 'defense', child: Text('Defense')),
            PopupMenuItem(value: 'blocking', child: Text('Blocking')),
          ],
        ),
        IconButton(
          tooltip: showAllCoverage ? 'Nur ausgewählte Coverage anzeigen' : 'Alle Coverage-Aufgaben anzeigen',
          onPressed: () => setState(() => showAllCoverage = !showAllCoverage),
          icon: Icon(showAllCoverage ? Icons.layers : Icons.layers_clear),
        ),
        IconButton(
          tooltip: 'Werkzeuge öffnen',
          onPressed: () => setState(() => toolsExpanded = true),
          icon: Icon(Icons.tune_rounded, color: accent),
        ),
      ]),
    );
  }

  Widget _controls({required bool landscape}) {
    final accent = Theme.of(context).colorScheme.primary;
    final actions = selected == null ? <PlayerRoute>[] : routes.where((r) => r.playerIndex == selected).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF102219),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .1))),
        borderRadius: landscape ? BorderRadius.circular(18) : const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton(tooltip: 'Werkzeuge schließen', onPressed: () => setState(() => toolsExpanded = false), icon: const Icon(Icons.keyboard_arrow_down)),
          CircleAvatar(radius: 16, backgroundColor: selected == null ? Colors.white12 : (selected! < 11 ? const Color(0xFF238EE8) : const Color(0xFFF25D63)),
            child: Icon(selected == null ? Icons.touch_app_outlined : Icons.person_outline, color: Colors.white, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_selectedLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Text(selected == null ? 'Spieler auf dem Feld antippen' : '${actions.length} Aufgaben · ${routeMode ? (freehand ? 'Freihand' : 'Punkte') : 'Verschieben'}',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ])),
          IconButton(
            tooltip: 'Passroute des Spielers löschen',
            onPressed: selected != null &&
                    routes.any((r) => r.playerIndex == selected && r.action == 'route')
                ? _deleteSelectedRoute
                : null,
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
          IconButton(tooltip: 'Auswahl aufheben', onPressed: selected == null ? null : () => setState(() => selected = null), icon: const Icon(Icons.close, size: 19)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            key: ValueKey('view_$viewFilter'),
            initialValue: viewFilter,
            isDense: true,
            decoration: const InputDecoration(labelText: 'Ansicht', isDense: true, border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Alle Aktionen')),
              DropdownMenuItem(value: 'offense', child: Text('Offense')),
              DropdownMenuItem(value: 'defense', child: Text('Defense')),
              DropdownMenuItem(value: 'blocking', child: Text('Blocking')),
            ],
            onChanged: (value) {
              if (value != null) { setState(() => viewFilter = value); }
            },
          )),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: focusSelected ? 'Alle Aufgaben anzeigen' : 'Ausgewaehlten Spieler fokussieren',
            onPressed: selected == null ? null : () => setState(() => focusSelected = !focusSelected),
            icon: Icon(focusSelected ? Icons.filter_center_focus : Icons.center_focus_weak),
          ),
        ]),
        if (targetMode != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(targetMode == 'block'
                ? 'Blockziel: Verteidiger antippen'
                : targetMode == 'man' ? 'Man Coverage: Receiver antippen'
                : 'Handoff: Ballempfänger antippen',
                style: TextStyle(color: accent, fontWeight: FontWeight.w600))),
            TextButton(onPressed: () => setState(() => targetMode = null),
                child: const Text('Abbrechen')),
          ]),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _toolButton(Icons.open_with, 'Bewegen', () => setState(() { routeMode = false; draft.clear(); }), active: !routeMode)),
          const SizedBox(width: 7),
          Expanded(child: _toolButton(Icons.alt_route, 'Zeichnen', () => setState(() { routeMode = true; draft.clear(); }), active: routeMode)),
          const SizedBox(width: 7),
          Expanded(child: _toolButton(Icons.auto_awesome_motion, 'Aktionen', _showPlayerActions)),
          const SizedBox(width: 7),
          Expanded(child: _toolButton(Icons.menu_book_outlined, 'Bibliothek', _showRouteLibrary)),
        ]),
        if (selected != null && selected! >= 11) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _showPlayerActions,
            icon: const Icon(Icons.shield_outlined), label: const Text('Coverage zuweisen / bearbeiten')),
          SwitchListTile.adaptive(title: const Text('Alle Coverage-Aufgaben anzeigen'),
            value: showAllCoverage, onChanged: (v) => setState(() => showAllCoverage = v)),
        ],
        if (selected != null && selected! < 11) ...[
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _startTargetAssignment('block'),
              icon: const Icon(Icons.shield_outlined, size: 18),
              label: const Text('Blockziel'),
            )),
            if (selected == 5) ...[
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _startTargetAssignment('handoff'),
                icon: const Icon(Icons.sports_football, size: 18),
                label: const Text('Handoff'),
              )),
            ],
          ]),
        ],
        if (routeMode) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: SegmentedButton<bool>(
              segments: const [ButtonSegment(value: true, label: Text('Freihand')), ButtonSegment(value: false, label: Text('Punkte'))],
              selected: {freehand}, showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() { freehand = v.first; draft.clear(); }),
            )),
            if (!freehand) ...[const SizedBox(width: 8), IconButton.filledTonal(onPressed: _finishDraw, tooltip: 'Route abschließen', icon: const Icon(Icons.check))],
          ]),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey('action_$drawingAction'), initialValue: drawingAction, isDense: true,
            decoration: const InputDecoration(labelText: 'Zeichenwerkzeug', isDense: true, border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'route', child: Text('Passroute')),
              DropdownMenuItem(value: 'run', child: Text('Laufweg')),
              DropdownMenuItem(value: 'movement', child: Text('QB-Bewegung')),
              DropdownMenuItem(value: 'block', child: Text('Run Block / Pull')),
              DropdownMenuItem(value: 'protection', child: Text('Pass Protection')),
              DropdownMenuItem(value: 'blitz', child: Text('Blitz')),
              DropdownMenuItem(value: 'coverage', child: Text('Coverage')),
              DropdownMenuItem(value: 'defense', child: Text('Run Fit / Defense')),
            ],
            onChanged: (v) { if (v != null) { setState(() => drawingAction = v); } },
          ),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 4, children: actions.map((r) => Chip(
            label: Text(r.name.isEmpty ? r.action : r.name, style: const TextStyle(fontSize: 11)),
            visualDensity: VisualDensity.compact,
            deleteIcon: const Icon(Icons.close, size: 15),
            onDeleted: () { setState(() => routes.remove(r)); _saveRoutes(); },
          )).toList()),
        ],
        const SizedBox(height: 8),
        Row(children: [
          TextButton.icon(onPressed: _saveTemplate, icon: const Icon(Icons.bookmark_add_outlined, size: 18), label: const Text('Vorlage')),
          TextButton.icon(onPressed: _undoLastAction, icon: const Icon(Icons.undo, size: 18), label: const Text('Rückgängig')),
          const Spacer(),
          TextButton(onPressed: () => setState(() { routeMode = false; selected = null; draft.clear(); }), child: Text('Fertig', style: TextStyle(color: accent))),
        ]),
      ])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          Text('${formation.label} · ${defenseFormation.label}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ]),
        actions: [
          IconButton(tooltip: 'Formation', icon: const Icon(Icons.grid_view_rounded), onPressed: _openFormations),
          IconButton(tooltip: 'Defense anzeigen', icon: Icon(showDefense ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() { showDefense = !showDefense; selected = null; })),
        ],
      ),
      body: SafeArea(child: Column(children: [
        Expanded(child: landscape
          ? Row(children: [
              Expanded(child: Padding(padding: const EdgeInsets.all(8), child: ClipRRect(borderRadius: BorderRadius.circular(16), child: _field()))),
              if (toolsExpanded) SizedBox(width: 300, child: Padding(padding: const EdgeInsets.fromLTRB(0, 8, 8, 8), child: _controls(landscape: true))) else SizedBox(width: 62, child: Center(child: IconButton(tooltip: 'Werkzeuge öffnen', onPressed: () => setState(() => toolsExpanded = true), icon: const Icon(Icons.tune_rounded)))),
            ])
          : Column(children: [
              Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(10, 4, 10, 8), child: ClipRRect(borderRadius: BorderRadius.circular(16), child: _field()))),
              if (toolsExpanded) ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .43), child: _controls(landscape: false)) else _compactControls(),
            ])),
      ])),
    );
  }

  void selectAt(Offset point, Size size) {
    int? closest;
    var minDistance = 28.0;
    for (var i = 0; i < positions.length; i++) {
      if (!showDefense && i >= 11) {
        continue;
      }
      final p = Offset(
        positions[i].dx * size.width,
        positions[i].dy * size.height,
      );
      final distance = (p - point).distance;
      if (distance < minDistance) {
        closest = i;
        minDistance = distance;
      }
    }
    setState(() => selected = closest);
  }
}
