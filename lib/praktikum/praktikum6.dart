import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../services/webrtc_service.dart';

class Praktikum6 extends StatefulWidget {
  const Praktikum6({super.key});

  @override
  State<Praktikum6> createState() => _Praktikum6State();
}

class _Praktikum6State extends State<Praktikum6> {
  final WebRTCService webrtc = WebRTCService();
  final TextEditingController roomController = TextEditingController(
    text: 'ruang-kampus-01',
  );

  WebRTCRole selectedRole = WebRTCRole.caller;
  String status = 'Belum terhubung';
  bool isConnected = false;
  bool microphoneEnabled = true;
  bool cameraEnabled = true;
  bool isLoading = false;

  Future<void> connect() async {
    final room = roomController.text.trim();
    if (room.isEmpty) {
      setState(() {
        status = 'Masukkan Room ID terlebih dahulu';
      });
      return;
    }

    setState(() {
      isLoading = true;
      status = 'Menyiapkan WebRTC...';
    });

    try {
      await webrtc.initialize(
        room: room,
        userRole: selectedRole,
        statusCallback: (message) {
          if (mounted) setState(() => status = message);
        },
        callStateCallback: (connected) {
          if (mounted) setState(() => isConnected = connected);
        },
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          isConnected = false;
          status = 'Gagal memulai WebRTC: $error';
        });
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> disconnect() async {
    await webrtc.disconnect();
    if (!mounted) return;

    setState(() {
      isConnected = false;
      status = 'Panggilan selesai';
      microphoneEnabled = true;
      cameraEnabled = true;
    });
  }

  void toggleMicrophone() {
    final newValue = !microphoneEnabled;
    webrtc.toggleMicrophone(newValue);
    setState(() => microphoneEnabled = newValue);
  }

  void toggleCamera() {
    final newValue = !cameraEnabled;
    webrtc.toggleCamera(newValue);
    setState(() => cameraEnabled = newValue);
  }

  @override
  void dispose() {
    webrtc.dispose();
    roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionActive = isConnected || isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Praktikum 6 - WebRTC')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Video Call Peer-to-Peer',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Buka room dan role yang sama dari dua tab/perangkat Chrome. '
            'Izinkan akses kamera dan mikrofon saat diminta.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: roomController,
            enabled: !sessionActive,
            decoration: const InputDecoration(
              labelText: 'Room ID',
              hintText: 'Masukkan nama room',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.meeting_room),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<WebRTCRole>(
            segments: const [
              ButtonSegment(
                value: WebRTCRole.caller,
                label: Text('Caller'),
                icon: Icon(Icons.call),
              ),
              ButtonSegment(
                value: WebRTCRole.callee,
                label: Text('Callee'),
                icon: Icon(Icons.phone),
              ),
            ],
            selected: {selectedRole},
            onSelectionChanged: sessionActive
                ? null
                : (selection) {
                    setState(() => selectedRole = selection.first);
                  },
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.circle,
                color: isConnected ? Colors.green : Colors.orange,
              ),
              title: const Text('Status WebRTC'),
              subtitle: Text(status),
            ),
          ),
          const SizedBox(height: 12),
          _VideoPanel(
            title: 'Video lokal',
            renderer: webrtc.localRenderer,
            placeholder: 'Kamera lokal belum aktif',
            mirror: true,
          ),
          const SizedBox(height: 12),
          _VideoPanel(
            title: 'Video peserta lain',
            renderer: webrtc.remoteRenderer,
            placeholder: 'Menunggu video peserta lain',
          ),
          const SizedBox(height: 16),
          if (isConnected) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: toggleMicrophone,
                    icon: Icon(microphoneEnabled ? Icons.mic : Icons.mic_off),
                    label: Text(
                      microphoneEnabled ? 'Matikan mic' : 'Nyalakan mic',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: toggleCamera,
                    icon: Icon(
                      cameraEnabled ? Icons.videocam : Icons.videocam_off,
                    ),
                    label: Text(
                      cameraEnabled ? 'Matikan kamera' : 'Nyalakan kamera',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: disconnect,
                icon: const Icon(Icons.call_end),
                label: const Text('Akhiri panggilan'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : connect,
                child: Text(isLoading ? 'Menghubungkan...' : 'Mulai WebRTC'),
              ),
            ),
        ],
      ),
    );
  }
}

class _VideoPanel extends StatelessWidget {
  const _VideoPanel({
    required this.title,
    required this.renderer,
    required this.placeholder,
    this.mirror = false,
  });

  final String title;
  final RTCVideoRenderer renderer;
  final String placeholder;
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: renderer.srcObject == null
                ? ColoredBox(
                    color: Colors.black87,
                    child: Center(
                      child: Text(
                        placeholder,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                : RTCVideoView(renderer, mirror: mirror),
          ),
        ],
      ),
    );
  }
}
