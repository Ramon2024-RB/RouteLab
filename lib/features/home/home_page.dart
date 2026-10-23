import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/play_model.dart';
import '../../data/repositories/play_repository.dart';
import '../play_editor/play_editor_page.dart';
import '../playbooks/widgets/create_play_dialog.dart';

class RouteLabHome extends StatefulWidget {
  const RouteLabHome({super.key});

  @override
  State<RouteLabHome> createState() => _RouteLabHomeState();
}

class _RouteLabHomeState extends State<RouteLabHome> {
  int tab = 0;
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
          initialPositions: play.positions,
          onPositionsChanged: (updated) {
            play.positions = List<Offset>.from(updated);
            _savePlays();
          },
        ),
      ),
    );
  }

  Future<void> createPlay() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const CreatePlayDialog(),
    );
    if (!mounted || name == null || name.isEmpty) return;
    final play = SavedPlay(
      id: const Uuid().v4(),
      name: name,
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                'assets/images/routelab_logo.png',
                width: 38,
                height: 38,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 11),
            const Text(
              'RouteLab',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Einstellungen folgen in einer späteren Version.',
                ),
              ),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: tab == 0
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    const Text(
                      'Design. Animate. Execute.',
                      style: TextStyle(color: green, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Deine Plays.\nDein Gameplan.',
                      style: TextStyle(
                        fontSize: 33,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Card(
                      color: const Color(0xFF153024),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.route, color: green, size: 35),
                            const SizedBox(height: 12),
                            const Text(
                              'Erstelle deinen nächsten Spielzug',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Positioniere Spieler auf dem Feld und plane ihre Bewegungen.',
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: createPlay,
                              icon: const Icon(Icons.add),
                              label: const Text('Neues Play'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      'Meine Plays (${plays.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : plays.isEmpty
                          ? const Center(
                              child: Text(
                                'Noch keine Plays erstellt.',
                                style: TextStyle(color: Colors.white60),
                              ),
                            )
                          : ListView.builder(
                              itemCount: plays.length,
                              itemBuilder: (context, i) => Card(
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.sports_football,
                                    color: green,
                                  ),
                                  title: Text(plays[i].name),
                                  trailing: IconButton(
                                    tooltip: 'Spielzug löschen',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => deletePlay(i),
                                  ),
                                  onTap: () => openPlay(plays[i]),
                                ),
                              ),
                            ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Playbooks',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Deine Spielzüge werden auf diesem Gerät gespeichert.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: ListView.builder(
                        itemCount: loading ? 0 : plays.length,
                        itemBuilder: (context, i) => ListTile(
                          title: Text(plays[i].name),
                          leading: const Icon(Icons.route, color: green),
                          trailing: IconButton(
                            tooltip: 'Spielzug löschen',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => deletePlay(i),
                          ),
                          onTap: () => openPlay(plays[i]),
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: createPlay,
                      icon: const Icon(Icons.add),
                      label: const Text('Neues Play'),
                    ),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Start',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Playbooks',
          ),
        ],
      ),
    );
  }
}
