import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/play_model.dart';
import '../../data/models/coverage_assignment.dart';
import '../../data/models/route_model.dart';
import '../../data/repositories/play_repository.dart';
import '../play_editor/play_editor_page.dart';
import '../playbooks/widgets/create_play_dialog.dart';

class RouteLabHome extends StatefulWidget {
  const RouteLabHome({super.key});

  @override
  State<RouteLabHome> createState() => _RouteLabHomeState();
}

class _RouteLabHomeState extends State<RouteLabHome> {
  PlayCategory? category;
  final plays = <SavedPlay>[];
  final storage = PlayStorage();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlays();
  }

  Future<void> _loadPlays() async {
    try {
      final saved = await storage.load();
      if (!mounted) return;
      setState(() {
        plays.addAll(saved);
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      _showError('Spielzüge konnten nicht geladen werden: $error');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _savePlays() async {
    try {
      await storage.save(plays);
    } catch (error) {
      _showError('Speichern fehlgeschlagen: $error');
    }
  }

  Future<void> openPlay(SavedPlay play) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayEditor(
          title: play.name,
          category: play.category,
          initialPositions: play.positions,
          initialRoutes: play.routes,
          initialCoverages: play.coverages,
          onCoveragesChanged: (List<CoverageAssignment> updated) {
            play.coverages = List<CoverageAssignment>.of(updated);
            _savePlays();
          },
          onRoutesChanged: (updated) {
            play.routes = List<PlayerRoute>.from(updated);
            _savePlays();
          },
          onPositionsChanged: (updated) {
            play.positions = List<Offset>.from(updated);
            _savePlays();
          },
        ),
      ),
    );
  }

  Future<void> movePlay(SavedPlay play, PlayCategory target) async {
    setState(() => play.category = target);
    await _savePlays();
  }

  Future<void> createPlay() async {
    final currentCategory = category;
    if (currentCategory == null) return;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const CreatePlayDialog(),
    );
    if (!mounted || name == null || name.isEmpty) return;
    final play = SavedPlay(
      id: const Uuid().v4(),
      name: name,
      category: currentCategory,
      positions: defaultPlayerPositions(),
    );
    setState(() => plays.add(play));
    await _savePlays();
    if (!mounted) return;
    await openPlay(play);
  }

  Future<void> deletePlay(int index) async {
    if (index < 0 || index >= plays.length) return;
    final play = plays[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Spielzug löschen?'),
        content: Text('Möchtest du „${play.name}“ wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Löschen',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => plays.removeWhere((entry) => entry.id == play.id));
    await _savePlays();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF39F47B);
    final current = category;
    final visible = current == null ? <SavedPlay>[] :
        plays.where((p) => p.category == current).toList();
    return Scaffold(
      appBar: AppBar(
        leading: current == null ? null : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => category = null),
        ),
        title: Text(current == null ? 'RouteLab' : '${current.label} Playbook',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: current == null
          ? ListView(padding: const EdgeInsets.all(20), children: [
              const SizedBox(height: 18),
              const Text('DESIGN. STUDY. EXECUTE.',
                  style: TextStyle(color: green, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              const Text('Dein Gameplan.\nDeine Playbooks.',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              for (final item in PlayCategory.values) ...[
                Card(color: const Color(0xFF153024), clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => setState(() => category = item),
                    child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
                      Icon(_icon(item), color: green, size: 32),
                      const SizedBox(width: 18),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(_description(item), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 9),
                          Text('${plays.where((p) => p.category == item).length} Plays',
                            style: const TextStyle(color: green)),
                        ])),
                      const Icon(Icons.chevron_right),
                    ])),
                  )),
                const SizedBox(height: 12),
              ],
              if (loading) const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              const Text('Bisherige Plays werden zunächst unter Offense angezeigt und können verschoben werden.',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ])
          : Column(children: [
              Padding(padding: const EdgeInsets.all(20), child: Row(children: [
                Icon(_icon(current), color: green),
                const SizedBox(width: 12),
                Expanded(child: Text(_description(current),
                  style: const TextStyle(color: Colors.white70))),
              ])),
              Expanded(child: loading
                ? const Center(child: CircularProgressIndicator())
                : visible.isEmpty
                  ? const Center(child: Text('Noch keine Plays in diesem Playbook.'))
                  : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final play = visible[index];
                      return Card(child: ListTile(
                        leading: Icon(_icon(current), color: green),
                        title: Text(play.name),
                        onTap: () => openPlay(play),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Play verwalten',
                          onSelected: (value) {
                            if (value == 'delete') {
                              final actualIndex = plays.indexWhere((p) => p.id == play.id);
                              deletePlay(actualIndex);
                            } else {
                              movePlay(play, PlayCategory.values.firstWhere((v) => v.name == value));
                            }
                          },
                          itemBuilder: (_) => [
                            for (final target in PlayCategory.values)
                              if (target != current)
                                PopupMenuItem(value: target.name,
                                  child: Text('Zu ${target.label} verschieben')),
                            const PopupMenuDivider(),
                            const PopupMenuItem(value: 'delete', child: Text('Löschen')),
                          ],
                        ),
                      ));
                    },
                  )),
              Padding(padding: const EdgeInsets.all(20), child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: createPlay,
                  icon: const Icon(Icons.add),
                  label: Text('Neues ${current.label} Play'),
                ),
              )),
            ]),
      ),
    );
  }

  IconData _icon(PlayCategory value) => switch (value) {
    PlayCategory.offense => Icons.trending_up,
    PlayCategory.defense => Icons.shield_outlined,
    PlayCategory.specialTeams => Icons.sports_football,
  };

  String _description(PlayCategory value) => switch (value) {
    PlayCategory.offense => 'Runs · Passes · Blocking · Motion',
    PlayCategory.defense => 'Fronts · Coverage · Blitz',
    PlayCategory.specialTeams => 'Kickoff · Punt · Return · Field Goal',
  };
}
