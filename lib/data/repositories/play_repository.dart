import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/play_model.dart';

class PlayStorage {
  Future<void> _pending = Future<void>.value();

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/routelab_plays.json');
  }

  Future<List<SavedPlay>> load() async {
    final file = await _file();
    if (!await file.exists()) return [];
    final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
    return decoded
        .map((item) => SavedPlay.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<SavedPlay> plays) {
    final snapshot = jsonEncode(plays.map((play) => play.toJson()).toList());
    _pending = _pending.catchError((Object _) {}).then((_) async {
      final file = await _file();
      await file.writeAsString(snapshot, flush: true);
    });
    return _pending;
  }
}
