import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'stopwatch.dart';
import 'timer.dart';
import 'history.dart';
import 'alarm_ringing.dart';
import 'package:audioplayers/audioplayers.dart';
import 'history_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class Alarm {
  final String time;
  final String period; // "AM" or "PM"
  bool enabled;
  final String sound;
  final String? customSoundPath;

  Alarm({required this.time, required this.period, required this.enabled, this.sound = 'alarm1.mp3', this.customSoundPath});

  Map<String, dynamic> toJson() =>
      {'time': time, 'period': period, 'enabled': enabled, 'sound': sound, 'customSoundPath': customSoundPath};

  static Alarm fromJson(Map<String, dynamic> json) => Alarm(
        time: json['time'],
        period: json['period'],
        enabled: json['enabled'],
        sound: json['sound'] ?? 'alarm1.mp3',
        customSoundPath: json['customSoundPath'],
      );
}

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({Key? key}) : super(key: key);

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  List<Alarm> alarms = [
    Alarm(time: "06:00", period: "AM", enabled: true),
    Alarm(time: "08:00", period: "AM", enabled: true),
    Alarm(time: "03:00", period: "PM", enabled: true),
    Alarm(time: "09:00", period: "PM", enabled: true),
  ];

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _loadAlarms();
    _startAlarmChecker();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    if (kIsWeb) return;
    
    try {
      // Request notification permissions
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        // Request notification permission
        final bool? granted = await androidImplementation.requestNotificationsPermission();
        print('Notification permission granted: $granted');

        // Request exact alarm permission for Android 12 and above
        if (await androidImplementation.requestExactAlarmsPermission()) {
          print('Exact alarm permission granted');
        } else {
          print('Exact alarm permission denied');
        }

        // Check if notifications are enabled
        final bool? notificationsEnabled = await androidImplementation.areNotificationsEnabled();
        print('Notifications enabled: $notificationsEnabled');
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          print('Notification response received: ${response.actionId}');
          if (response.payload != null) {
            final alarmData = jsonDecode(response.payload!);
            final alarm = Alarm.fromJson(alarmData);
            if (response.actionId == 'stop_alarm') {
              await _audioPlayer?.stop();
              _ringing = false;
              final index = alarms.indexWhere((a) => 
                a.time == alarm.time && a.period == alarm.period);
              if (index != -1) {
                setState(() {
                  alarms[index].enabled = false;
                });
                _saveAlarms();
              }
            } else if (response.actionId == 'snooze_alarm') {
              await _audioPlayer?.stop();
              _ringing = false;
              // Schedule a new alarm for 5 minutes later
              final now = DateTime.now();
              final snoozeTime = now.add(const Duration(minutes: 5));
              final snoozeAlarm = Alarm(
                time: '${snoozeTime.hour.toString().padLeft(2, '0')}:${snoozeTime.minute.toString().padLeft(2, '0')}',
                period: snoozeTime.hour < 12 ? 'AM' : 'PM',
                enabled: true,
                sound: alarm.sound,
                customSoundPath: alarm.customSoundPath,
              );
              setState(() {
                alarms.add(snoozeAlarm);
              });
              _saveAlarms();
            } else if (response.actionId == 'dismiss_alarm') {
              await _audioPlayer?.stop();
              _ringing = false;
            } else {
              _showAlarmRinging(alarm);
            }
          }
        },
      );

      // Create notification channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'alarm_channel',
        'Alarm Notifications',
        description: 'Notification channel for alarm',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        enableLights: true,
      );

      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        print('Notification channel created successfully');
      }
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> _scheduleAlarmNotification(Alarm alarm, int id) async {
    if (kIsWeb) return;
    
    try {
      final now = DateTime.now();
      int hour = int.parse(alarm.time.split(":")[0]);
      int minute = int.parse(alarm.time.split(":")[1]);
      if (alarm.period == "PM" && hour != 12) hour += 12;
      if (alarm.period == "AM" && hour == 12) hour = 0;
      
      tz.TZDateTime scheduledTime = tz.TZDateTime.from(
        DateTime(now.year, now.month, now.day, hour, minute),
        tz.local,
      );
      
      if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      print('Scheduling alarm for: ${scheduledTime.toString()}');

      const AndroidNotificationAction stopAction = AndroidNotificationAction(
        'stop_alarm',
        'Stop Alarm',
        showsUserInterface: true,
        cancelNotification: true,
      );

      const AndroidNotificationAction snoozeAction = AndroidNotificationAction(
        'snooze_alarm',
        'Snooze',
        showsUserInterface: true,
      );

      const AndroidNotificationAction dismissAction = AndroidNotificationAction(
        'dismiss_alarm',
        'Dismiss',
        showsUserInterface: true,
        cancelNotification: true,
      );

      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'alarm_channel',
        'Alarm Notifications',
        channelDescription: 'Notification channel for alarm',
        importance: Importance.max,
        priority: Priority.max,
        sound: RawResourceAndroidNotificationSound('alarm1'),
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        actions: [stopAction, snoozeAction, dismissAction],
        ongoing: false,
        autoCancel: true,
        channelShowBadge: true,
        enableLights: true,
        color: Color(0xFF162B34),
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      // Cancel any existing notification for this alarm
      await flutterLocalNotificationsPlugin.cancel(id);

      // Schedule the new notification
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Alarm',
        'Alarm for ${alarm.time} ${alarm.period}',
        scheduledTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: jsonEncode(alarm.toJson()),
      );
      print('Alarm scheduled successfully for ID: $id');
    } catch (e) {
      print('Error scheduling alarm: $e');
    }
  }

  Future<void> _cancelAlarmNotification(int id) async {
    if (kIsWeb) return;
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmList = prefs.getString('alarms');
    if (alarmList != null) {
      final List<dynamic> decoded = jsonDecode(alarmList);
      setState(() {
        alarms = decoded.map((e) => Alarm.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(alarms.map((e) => e.toJson()).toList());
    await prefs.setString('alarms', encoded);
    // Schedule notifications for all enabled alarms
    for (int i = 0; i < alarms.length; i++) {
      if (alarms[i].enabled) {
        _scheduleAlarmNotification(alarms[i], i);
      } else {
        _cancelAlarmNotification(i);
      }
    }
  }

  void _toggleAlarm(int index, bool value) {
    setState(() {
      alarms[index].enabled = value;
    });
    _saveAlarms();
    if (alarms[index].enabled) {
      _scheduleAlarmNotification(alarms[index], index);
    } else {
      _cancelAlarmNotification(index);
    }
  }

  void _showAddAlarmDialog() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddAlarmSheet(),
    );

    if (result != null) {
      setState(() {
        alarms.add(Alarm(
          time: result['time'],
          period: result['period'],
          enabled: true,
          sound: result['sound'],
          customSoundPath: result['customSoundPath'],
        ));
      });
      _saveAlarms();
    }
  }

  AudioPlayer? _audioPlayer;
  bool _ringing = false;

  void _startAlarmChecker() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _ringing) return true;
      final now = DateTime.now();
      final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
      final minute = now.minute;
      final ampm = now.hour < 12 ? 'AM' : 'PM';
      final nowStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      for (final alarm in alarms) {
        if (alarm.enabled && alarm.time == nowStr && alarm.period == ampm) {
          _ringing = true;
          _showAlarmRinging(alarm);
          break;
        }
      }
      return true;
    });
  }

  void _showAlarmRinging(Alarm alarm) async {
    _audioPlayer = AudioPlayer();
    await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
    if (alarm.customSoundPath != null) {
      await _audioPlayer!.play(DeviceFileSource(alarm.customSoundPath!), volume: 1.0);
    } else {
      await _audioPlayer!.play(AssetSource('sounds/${alarm.sound}'), volume: 1.0);
    }

    // Show notification when alarm triggers
    const AndroidNotificationAction stopAction = AndroidNotificationAction(
      'stop_alarm',
      'Stop Alarm',
      showsUserInterface: true,
      cancelNotification: true,
    );

    const AndroidNotificationAction snoozeAction = AndroidNotificationAction(
      'snooze_alarm',
      'Snooze',
      showsUserInterface: true,
    );

    const AndroidNotificationAction dismissAction = AndroidNotificationAction(
      'dismiss_alarm',
      'Dismiss',
      showsUserInterface: true,
      cancelNotification: true,
    );

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      channelDescription: 'Notification channel for alarm',
      importance: Importance.max,
      priority: Priority.max,
      sound: RawResourceAndroidNotificationSound('alarm1'),
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      actions: [stopAction, snoozeAction, dismissAction],
      ongoing: false,
      autoCancel: true,
      channelShowBadge: true,
      enableLights: true,
      color: Color(0xFF162B34),
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      alarm.hashCode,
      'Alarm',
      'Time to wake up!',
      platformChannelSpecifics,
      payload: jsonEncode(alarm.toJson()),
    );

    if (!mounted) return;
    // Save to history
    HistoryStorage.addEvent(HistoryEvent(
      type: 'alarm',
      description: 'Alarm rang at ${alarm.time} ${alarm.period}',
      timestamp: DateTime.now(),
    ));
    // Show ringing UI
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AlarmRingingScreen(
          time: '${alarm.time} ${alarm.period}',
          soundName: alarm.customSoundPath != null ? 'Custom' : alarm.sound,
          onStop: () async {
            await _audioPlayer?.stop();
            Navigator.of(context).pop();
            setState(() {
              alarm.enabled = false;
            });
            _saveAlarms();
            _ringing = false;
          },
        ),
      ),
    );
    await _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _audioPlayer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162B34),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(96),
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 56),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TabButton(
                      label: "Alarm",
                      selected: true,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const AlarmScreen()),
                        );
                      },
                    ),
                    _TabButton(
                      label: "Stopwatch",
                      selected: false,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const StopwatchScreen()),
                        );
                      },
                    ),
                    _TabButton(
                      label: "Timer",
                      selected: false,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const TimerScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 44,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  showMenu(
                    context: context,
                    position: const RelativeRect.fromLTRB(1000, 80, 0, 0),
                    items: [
                      PopupMenuItem(
                        value: 'History',
                        child: const Text('History'),
                        onTap: () {
                          Future.delayed(Duration.zero, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HistoryScreen()),
                            );
                          });
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          ...alarms.asMap().entries.map((entry) {
            final index = entry.key;
            final alarm = entry.value;
            return GestureDetector(
              onTap: () async {
                final result = await showModalBottomSheet<Map<String, dynamic>>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => _AddAlarmSheet(
                    initialHour: int.parse(alarm.time.split(":")[0]),
                    initialMinute: int.parse(alarm.time.split(":")[1]),
                    initialPeriod: alarm.period,
                    initialSound: alarm.sound,
                    initialCustomSoundPath: alarm.customSoundPath,
                    isEdit: true,
                  ),
                );
                if (result != null) {
                  setState(() {
                    alarms[index] = Alarm(
                      time: result['time'],
                      period: result['period'],
                      enabled: alarm.enabled,
                      sound: result['sound'],
                      customSoundPath: result['customSoundPath'],
                    );
                  });
                  _saveAlarms();
                }
              },
              onLongPress: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF22343C),
                    title: const Text('Delete Alarm', style: TextStyle(color: Colors.white)),
                    content: const Text('Are you sure you want to delete this alarm?', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  setState(() {
                    alarms.removeAt(index);
                  });
                  _saveAlarms();
                  await _cancelAlarmNotification(index);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      alarm.time,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      alarm.period,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: alarm.enabled,
                      activeColor: Colors.green,
                      onChanged: (value) => _toggleAlarm(index, value),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              elevation: 2,
              child: const Icon(Icons.add, color: Colors.black, size: 36),
              onPressed: _showAddAlarmDialog,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: selected
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _AddAlarmSheet extends StatefulWidget {
  final int? initialHour;
  final int? initialMinute;
  final String? initialPeriod;
  final String? initialSound;
  final String? initialCustomSoundPath;
  final bool isEdit;
  const _AddAlarmSheet({this.initialHour, this.initialMinute, this.initialPeriod, this.initialSound, this.initialCustomSoundPath, this.isEdit = false});

  @override
  State<_AddAlarmSheet> createState() => _AddAlarmSheetState();
}

class _AddAlarmSheetState extends State<_AddAlarmSheet> {
  late int hour;
  late int minute;
  late String period;
  late String sound;
  String? customSoundPath;

  @override
  void initState() {
    super.initState();
    hour = widget.initialHour ?? 6;
    minute = widget.initialMinute ?? 0;
    period = widget.initialPeriod ?? "AM";
    sound = widget.initialSound ?? 'alarm1.mp3';
    customSoundPath = widget.initialCustomSoundPath;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(top: 32, left: 24, right: 24, bottom: 24),
        decoration: const BoxDecoration(
          color: Color(0xFF162B34),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.white, size: 32),
                  onPressed: () {
                    final timeStr = hour.toString().padLeft(2, '0') +
                        ':' +
                        minute.toString().padLeft(2, '0');
                    Navigator.pop(context, {
                      'time': timeStr,
                      'period': period,
                      'sound': sound,
                      'customSoundPath': customSoundPath,
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "New Alarm",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hour picker
                SizedBox(
                  width: 60,
                  height: 120,
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 40,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) => setState(() => hour = i + 1),
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, i) {
                        if (i < 0 || i > 11) return null;
                        return Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: hour == i + 1 ? Colors.white : Colors.white38,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                    controller: FixedExtentScrollController(initialItem: hour - 1),
                  ),
                ),
                const SizedBox(width: 8),
                // Minute picker
                SizedBox(
                  width: 60,
                  height: 120,
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 40,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) => setState(() => minute = i),
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, i) {
                        if (i < 0 || i > 59) return null;
                        return Center(
                          child: Text(
                            i.toString().padLeft(2, '0'),
                            style: TextStyle(
                              color: minute == i ? Colors.white : Colors.white38,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                    controller: FixedExtentScrollController(initialItem: minute),
                  ),
                ),
                const SizedBox(width: 16),
                // AM/PM toggle
                Column(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => period = "AM"),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: period == "AM" ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: period == "AM"
                              ? [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))]
                              : [],
                        ),
                        child: Text(
                          "AM",
                          style: TextStyle(
                            color: period == "AM" ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => period = "PM"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: period == "PM" ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: period == "PM"
                              ? [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))]
                              : [],
                        ),
                        child: Text(
                          "PM",
                          style: TextStyle(
                            color: period == "PM" ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Sound",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Sound picker
                SizedBox(
                  width: 120,
                  height: 120,
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 40,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) => setState(() {
                      sound = 'alarm${i + 1}.mp3';
                      customSoundPath = null;
                    }),
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, i) {
                        if (i < 0 || i > 9) return null;
                        return Center(
                          child: Text(
                            'alarm${i + 1}.mp3',
                            style: TextStyle(
                              color: sound == 'alarm${i + 1}.mp3' && customSoundPath == null ? Colors.white : Colors.white38,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                    controller: FixedExtentScrollController(initialItem: int.tryParse(sound.replaceAll(RegExp(r'[^0-9]'), '')) != null ? int.parse(sound.replaceAll(RegExp(r'[^0-9]'), '')) - 1 : 0),
                  ),
                ),
                const SizedBox(width: 16),
                // Custom sound picker button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: customSoundPath != null ? Colors.green : Colors.blueGrey,
                  ),
                  icon: const Icon(Icons.upload_file, color: Colors.white),
                  label: Text(
                    customSoundPath != null ? 'Custom' : 'Import',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
                    if (result != null && result.files.single.path != null) {
                      setState(() {
                        customSoundPath = result.files.single.path;
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}