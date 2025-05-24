import 'package:flutter/material.dart';
import 'dart:async';
import 'alarm.dart';
import 'timer.dart';
import 'history.dart';
import 'history_storage.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({Key? key}) : super(key: key);

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  Duration elapsed = const Duration(hours: 1, minutes: 30, seconds: 20);
  Timer? _timer;
  bool running = false;

  void _start() {
    if (_timer != null) return;
    setState(() => running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        elapsed += const Duration(seconds: 1);
      });
    });
  }

  void _pause() {
    setState(() => running = false);
    _timer?.cancel();
    _timer = null;
  }

  void _reset() {
    _pause();
    setState(() => elapsed = Duration.zero);
  }

  void _stop() {
    if (elapsed > Duration.zero) {
      HistoryStorage.addEvent(
        HistoryEvent(
          type: 'stopwatch',
          description: 'Stopwatch stopped at ${_twoDigits(elapsed.inHours)}:${_twoDigits(elapsed.inMinutes.remainder(60))}:${_twoDigits(elapsed.inSeconds.remainder(60))}',
          timestamp: DateTime.now(),
        ),
      );
    }
    _reset();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final hours = _twoDigits(elapsed.inHours);
    final minutes = _twoDigits(elapsed.inMinutes.remainder(60));
    final seconds = _twoDigits(elapsed.inSeconds.remainder(60));

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
                selected: true,
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
          const SizedBox(height: 60),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$hours:$minutes:$seconds",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CircleButton(
                icon: Icons.replay,
                onTap: _reset,
              ),
              const SizedBox(width: 24),
              _CircleButton(
                icon: running ? Icons.pause : Icons.play_arrow,
                onTap: running ? _pause : _start,
              ),
              const SizedBox(width: 24),
              _CircleButton(
                icon: Icons.stop,
                onTap: _stop,
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