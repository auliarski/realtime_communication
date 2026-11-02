
import 'package:flutter/material.dart';
import '../services/websocket_service.dart';

class Praktikum4 extends StatefulWidget {
  const Praktikum4({super.key});

  @override
  State<Praktikum4> createState() => _Praktikum4State();
}

class _Praktikum4State extends State<Praktikum4> {
  final WebSocketService webSocketService = WebSocketService();

  final TextEditingController messageController =
      TextEditingController();

  int counter = 0;
  int value = 0;

  String updatedAt = '-';
  String status = 'WebSocket Terputus';
  String? errorMessage;

  bool isConnected = false;
  bool isConnecting = false;

  final List<String> messages = [];

  // Menghubungkan ke server.
  Future<void> connectWebSocket() async {
    if (isConnected || isConnecting) return;

    setState(() {
      isConnecting = true;
      status = 'Menghubungkan...';
      errorMessage = null;
    });

    await webSocketService.connect(
      onConnected: () {
        if (!mounted) return;

        setState(() {
          isConnected = true;
          isConnecting = false;
          status = 'WebSocket Terhubung';
          messages.add('Berhasil terhubung ke server');
        });
      },

      onData: (data) {
        if (!mounted) return;

        setState(() {
          // Data pembaruan dari server.
          if (data.containsKey('counter')) {
            counter = data['counter'] ?? counter;
            value = data['value'] ?? value;
            updatedAt = data['timestamp']?.toString() ?? '-';
          }

          // Balasan pesan dari server.
          if (data['type'] == 'echo') {
            messages.add(
              'Server: ${data['message']}',
            );
          }
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
          status = 'WebSocket Terputus';
        });
      },
    );

    if (mounted && !isConnected) {
      setState(() {
        isConnecting = false;
      });
    }
  }

  // Mengirim pesan ke server.
  void sendMessage() {
    final message = messageController.text.trim();

    if (message.isEmpty || !isConnected) return;

    try {
      webSocketService.sendMessage(message);

      setState(() {
        messages.add('Kamu: $message');
        messageController.clear();
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  // Memutus koneksi WebSocket.
  Future<void> disconnectWebSocket() async {
    await webSocketService.disconnect();

    if (!mounted) return;

    setState(() {
      isConnected = false;
      isConnecting = false;
      status = 'WebSocket Terputus';
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    webSocketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Praktikum 4 - WebSocket'),
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

            const SizedBox(height: 15),

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

            const SizedBox(height: 10),

            // Tombol koneksi.
            ElevatedButton.icon(
              onPressed: (isConnected || isConnecting)
                  ? null
                  : connectWebSocket,
              icon: const Icon(Icons.link),
              label: const Text('Connect WebSocket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(14),
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: isConnected
                  ? disconnectWebSocket
                  : null,
              icon: const Icon(Icons.link_off),
              label: const Text('Disconnect WebSocket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(14),
              ),
            ),

            const SizedBox(height: 12),

            // Status koneksi.
            Text(
              'Status: $status',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isConnected ? Colors.green : Colors.red,
              ),
            ),

            if (isConnecting) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],

            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],

            const Divider(height: 30),

            const Text(
              'Kirim Pesan ke Server',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // Input pesan.
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    enabled: isConnected,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan pesan...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),

                const SizedBox(width: 8),

                IconButton(
                  onPressed: isConnected ? sendMessage : null,
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                  iconSize: 30,
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Text(
              'Riwayat Pesan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            // Daftar pesan.
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: messages.isEmpty
                    ? const Center(
                        child: Text('Belum ada pesan'),
                      )
                    : ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                            ),
                            child: Text(messages[index]),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
