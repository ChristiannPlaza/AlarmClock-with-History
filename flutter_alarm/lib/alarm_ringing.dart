import 'package:flutter/material.dart';

class AlarmRingingScreen extends StatelessWidget {
  final String time;
  final String? soundName;
  final VoidCallback onStop;
  const AlarmRingingScreen({Key? key, required this.time, this.soundName, required this.onStop}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162B34),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.alarm, color: Colors.white, size: 80),
              const SizedBox(height: 32),
              const Text(
                'Alarm Ringing',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(2, 2),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              if (soundName != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Sound: $soundName',
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
              const SizedBox(height: 48),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.stop, color: Colors.white),
                label: const Text(
                  'Stop',
                  style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: onStop,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 