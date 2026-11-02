
import 'package:flutter/material.dart';
import '../services/sse_service.dart';

class Praktikum3 extends StatefulWidget {
  const Praktikum3({super.key});

  @override
  State<Praktikum3> createState() => _Praktikum3State();
}

class _Praktikum3State extends State<Praktikum3> {
  final SseService sseService = SseService();

  int counter = 0;
  int value = 0;

  String updatedAt = '-';
  String status = 'SSE Berhenti';
  String? errorMessage;

  bool isConnected = false;
  bool isConnecting = false;

  // Memulai koneksi SSE.
  Future<void> startSSE() async {
    if (isConnected || isConnecting) return;

    setState(() {
      isConnecting = true;
      status = 'Menghubungkan...';
      errorMessage = null;
    });

    await sseService.connect(
      onConnected: () {
        if (!mounted) return;

        setState(() {
          isConnecting = false;
          isConnected = true;
          status = 'SSE Terhubung';
        });
      },

      onData: (data) {
        if (!mounted) return;

        setState(() {
          counter = data['counter'] ?? counter;
          value = data['value'] ?? value;
          updatedAt = data['timestamp']?.toString() ?? '-';
          errorMessage = null;
        });
      },

      onError: (error) {
        if (!mounted) return;

        setState(() {
          errorMessage = error;
          status = 'Terjadi Kesalahan';
          isConnected = false;
          isConnecting = false;
        });
      },

      onDisconnected: () {
        if (!mounted) return;

        setState(() {
          isConnected = false;
          isConnecting = false;
          status = 'SSE Terputus';
        });
      },
    );

    if (mounted && !isConnected) {
      setState(() {
        isConnecting = false;
      });
    }
  }

  // Menghentikan koneksi SSE.
  Future<void> stopSSE() async {
    await sseService.disconnect();

    if (!mounted) return;

    setState(() {
      isConnected = false;
      isConnecting = false;
      status = 'SSE Berhenti';
      errorMessage = null;
    });
  }

  @override
  void dispose() {
    sseService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Praktikum 3 - SSE'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Data dari Server',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Counter.
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.numbers,
                  color: Colors.blue,
                ),
                title: const Text('Counter'),
                trailing: Text(
                  '$counter',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Value.
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.bar_chart,
                  color: Colors.orange,
                ),
                title: const Text('Value'),
                trailing: Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Timestamp.
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.access_time,
                  color: Colors.green,
                ),
                title: const Text('Updated At'),
                subtitle: Text(updatedAt),
              ),
            ),

            const SizedBox(height: 20),

            // Tombol Start SSE.
            ElevatedButton.icon(
              onPressed:
                  (isConnected || isConnecting) ? null : startSSE,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start SSE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
              ),
            ),

            const SizedBox(height: 10),

            // Tombol Stop SSE.
            ElevatedButton.icon(
              onPressed:
                  (isConnected || isConnecting) ? stopSSE : null,
              icon: const Icon(Icons.stop),
              label: const Text('Stop SSE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.all(15),
              ),
            ),

            const SizedBox(height: 20),

            // Status koneksi.
            Text(
              'Status: $status',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isConnected
                    ? Colors.green
                    : Colors.red,
              ),
            ),

            if (isConnecting) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
            ],

            if (errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
