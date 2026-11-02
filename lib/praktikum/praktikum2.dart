
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class Praktikum2 extends StatefulWidget {
  const Praktikum2({super.key});

  @override
  State<Praktikum2> createState() => _Praktikum2State();
}

class _Praktikum2State extends State<Praktikum2> {
  final ApiService apiService = ApiService();

  Timer? pollingTimer;

  int counter = 0;
  int value = 0;

  String updatedAt = '-';
  String status = 'Polling Berhenti';
  String? errorMessage;

  bool isRunning = false;
  bool isLoading = false;

  // Mengambil data dari server.
  Future<void> fetchData() async {
    if (isLoading) return;

    isLoading = true;

    try {
      final data = await apiService.getData();

      if (!mounted) return;

      setState(() {
        counter = data['counter'] ?? 0;
        value = data['value'] ?? 0;
        updatedAt = data['timestamp']?.toString() ?? '-';
        errorMessage = null;
        status = isRunning
            ? 'Polling Aktif'
            : 'Polling Berhenti';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        status = 'Gagal Mengambil Data';
      });
    } finally {
      isLoading = false;
    }
  }

  // Memulai polling setiap 2 detik.
  void startPolling() {
    if (isRunning) return;

    setState(() {
      isRunning = true;
      status = 'Polling Aktif';
      errorMessage = null;
    });

    // Ambil data langsung saat tombol ditekan.
    fetchData();

    // Selanjutnya ambil data setiap 2 detik.
    pollingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) {
        fetchData();
      },
    );
  }

  // Menghentikan polling.
  void stopPolling() {
    pollingTimer?.cancel();
    pollingTimer = null;

    setState(() {
      isRunning = false;
      status = 'Polling Berhenti';
    });
  }

  @override
  void dispose() {
    pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Praktikum 2 - Polling'),
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

            // Menampilkan Counter.
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

            // Menampilkan Value.
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

            // Menampilkan waktu pembaruan.
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

            // Tombol Start.
            ElevatedButton.icon(
              onPressed: isRunning ? null : startPolling,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Polling'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
              ),
            ),

            const SizedBox(height: 10),

            // Tombol Stop.
            ElevatedButton.icon(
              onPressed: isRunning ? stopPolling : null,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Polling'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.all(15),
              ),
            ),

            const SizedBox(height: 20),

            // Status polling.
            Text(
              'Status: $status',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isRunning ? Colors.green : Colors.red,
              ),
            ),

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

            if (isLoading) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
