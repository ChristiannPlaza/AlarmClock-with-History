import 'package:flutter/material.dart';
import 'history_storage.dart';
import 'timer.dart';
import 'dart:async';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162B34),
      appBar: AppBar(
        backgroundColor: const Color(0xFF162B34),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF22343C),
            onSelected: (value) {
              if (value == 'History') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'History',
                child: Text('History'),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _HistoryButton(label: 'Alarm', onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventListScreen(type: 'alarm')),
              );
            }),
            const SizedBox(height: 20),
            _HistoryButton(label: 'Stopwatch', onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventListScreen(type: 'stopwatch')),
              );
            }),
            const SizedBox(height: 20),
            _HistoryButton(label: 'Timer', onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventListScreen(type: 'timer')),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _HistoryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _HistoryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey[350],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.5,
                fontFeatures: [FontFeature.enable('smcp')],
              ),
            ),
            const Spacer(),
            const Text(
              '>',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventListScreen extends StatelessWidget {
  final String type;
  const EventListScreen({Key? key, required this.type}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162B34),
      appBar: AppBar(
        backgroundColor: const Color(0xFF162B34),
        elevation: 0,
        title: Text(
          '${type[0].toUpperCase()}${type.substring(1)} History',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<HistoryEvent>>(
        future: HistoryStorage.getEvents(type: type),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data!;
          if (events.isEmpty) {
            return const Center(
              child: Text(
                'No history yet.',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            );
          }
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, i) {
              final e = events[events.length - 1 - i]; // show latest first
              return ListTile(
                title: Text(
                  e.description,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                subtitle: Text(
                  e.timestamp.toLocal().toString(),
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
