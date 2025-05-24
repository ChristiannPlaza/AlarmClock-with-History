import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryEvent {
  final String type; // 'alarm', 'stopwatch', 'timer'
  final String description;
  final DateTime timestamp;

  HistoryEvent({required this.type, required this.description, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'type': type,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
  };

  static HistoryEvent fromJson(Map<String, dynamic> json) => HistoryEvent(
    type: json['type'],
    description: json['description'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class HistoryStorage {
  static const _key = 'history_events';

  static Future<void> addEvent(HistoryEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.add(jsonEncode(event.toJson()));
    await prefs.setStringList(_key, list);
  }

  static Future<List<HistoryEvent>> getEvents({String? type}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final events = list.map((e) => HistoryEvent.fromJson(jsonDecode(e))).toList();
    if (type != null) {
      return events.where((e) => e.type == type).toList();
    }
    return events;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
} 