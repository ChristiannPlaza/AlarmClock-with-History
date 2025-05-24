import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'alarm.dart';
import 'stopwatch.dart';
import 'history.dart';
import 'history_storage.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({Key? key}) : super(key: key);

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Duration _duration = const Duration(minutes: 5, seconds: 30);
  Duration _remaining = const Duration(minutes: 5, seconds: 30);
  bool _running = false;
  Timer? _timer;

  void _onDurationChanged(Duration newDuration) {
    if (_running) return;
    setState(() {
      _duration = newDuration;
      _remaining = newDuration;
    });
  }

  void _start() {
    if (_remaining <= Duration.zero) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_remaining > Duration.zero) {
          _remaining -= const Duration(seconds: 1);
        }
        if (_remaining <= Duration.zero) {
          _remaining = Duration.zero;
          _running = false;
          _timer?.cancel();
          // Save to history
          HistoryStorage.addEvent(
            HistoryEvent(
              type: 'timer',
              description: 'Timer finished at ${_twoDigits(_duration.inHours)}:${_twoDigits(_duration.inMinutes.remainder(60))}:${_twoDigits(_duration.inSeconds.remainder(60))}',
              timestamp: DateTime.now(),
            ),
          );
        }
      });
    });
  }

  void _pause() {
    setState(() => _running = false);
    _timer?.cancel();
  }

  void _reset() {
    setState(() {
      _running = false;
      _remaining = _duration;
    });
    _timer?.cancel();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _twoDigits(_remaining.inHours);
    final minutes = _twoDigits(_remaining.inMinutes.remainder(60));
    final seconds = _twoDigits(_remaining.inSeconds.remainder(60));

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
                      selected: false,
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
                      selected: true,
                      onTap: () {},
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
          const SizedBox(height: 32),
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SizedBox(width: 40),
              Text("hrs", style: TextStyle(color: Colors.white54, fontSize: 16)),
              SizedBox(width: 40),
              Text("mins", style: TextStyle(color: Colors.white54, fontSize: 16)),
              SizedBox(width: 40),
              Text("sec", style: TextStyle(color: Colors.white54, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          // Timer picker
          SizedBox(
            height: 160,
            child: CupertinoTheme(
              data: const CupertinoThemeData(
                brightness: Brightness.dark,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              child: AbsorbPointer(
                absorbing: _running,
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hms,
                  initialTimerDuration: _duration,
                  onTimerDurationChanged: _onDurationChanged,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Digital timer display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("$hours:", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w400)),
              Text("$minutes:", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w400)),
              Text(seconds, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w400)),
            ],
          ),
          const Spacer(),
          // Buttons row (reset and play/pause)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CircleButton(
                icon: Icons.replay,
                onTap: _reset,
              ),
              const SizedBox(width: 24),
              _CircleButton(
                icon: _running ? Icons.pause : Icons.play_arrow,
                onTap: _running ? _pause : _start,
              ),
            ],
          ),
          const SizedBox(height: 48),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  )
                ],
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

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}
