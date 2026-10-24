import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/route_model.dart';

class RouteStorage {
  Future<void> _pending = Future<void>.value();
  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/routelab_route_templates.json');
  }
  Future<List<RouteTemplate>> load() async {
    final file = await _file();
    if (!await file.exists()) return [];
    final decoded = jsonDecode(await file.readAsString()) as List;
    return decoded.map((e) => RouteTemplate.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
  Future<void> save(List<RouteTemplate> templates) {
    final snapshot = jsonEncode(templates.map((e) => e.toJson()).toList());
    _pending = _pending.catchError((Object _) {}).then((_) async {
      await (await _file()).writeAsString(snapshot, flush: true);
    });
    return _pending;
  }
}
