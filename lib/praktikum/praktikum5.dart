
import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';

class Praktikum5 extends StatefulWidget {
  const Praktikum5({super.key});

  @override
  State<Praktikum5> createState() => _Praktikum5State();
}

class _Praktikum5State extends State<Praktikum5> {
  final MqttService mqttService = MqttService();

  String status = 'Belum terhubung';
  String temperature = '-';
  String timestamp = '-';

  final TextEditingController controller =
      TextEditingController(text: '28.5');

  bool isConnected = false;

  Future<void> connectMqtt() async {
    try {
      await mqttService.connect(
        onData: (data) {
          if (!mounted) return;

          setState(() {
            temperature = data['temperature'].toString();
            timestamp = data['timestamp'] ?? '-';
          });
        },
        onStatus: (message) {
          if (!mounted) return;

          setState(() {
            status = message;
            isConnected = mqttService.isConnected;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        isConnected = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        status = 'Koneksi gagal: $e';
        isConnected = false;
      });
    }
  }

  void publishData() {
    final value = double.tryParse(controller.text);

    if (value == null) {
      setState(() {
        status = 'Masukkan angka suhu yang valid';
      });
      return;
    }

    try {
      mqttService.publish(value);

      setState(() {
        status = 'Data suhu berhasil dikirim';
      });
    } catch (e) {
      setState(() {
        status = 'Gagal mengirim data: $e';
      });
    }
  }

  void disconnectMqtt() {
    mqttService.disconnect();

    setState(() {
      isConnected = false;
      status = 'MQTT terputus';
    });
  }

  @override
  void dispose() {
    mqttService.disconnect();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Praktikum 5 - MQTT'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              'Monitoring Sensor IoT',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: ListTile(
                title: const Text('Status Koneksi'),
                subtitle: Text(status),
                leading: Icon(
                  Icons.circle,
                  color: isConnected ? Colors.green : Colors.red,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Card(
              child: ListTile(
                title: const Text('Temperatur Sensor'),
                subtitle: Text(
                  '$temperature °C',
                  style: const TextStyle(fontSize: 28),
                ),
                leading: const Icon(
                  Icons.thermostat,
                  size: 35,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text('Waktu pembaruan: $timestamp'),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: isConnected ? null : connectMqtt,
              child: const Text('Connect MQTT'),
            ),

            ElevatedButton(
              onPressed: isConnected ? disconnectMqtt : null,
              child: const Text('Disconnect MQTT'),
            ),

            const Divider(height: 35),

            const Text(
              'Publish Data Sensor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Temperatur (°C)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: isConnected ? publishData : null,
              icon: const Icon(Icons.send),
              label: const Text('Publish Data'),
            ),
          ],
        ),
      ),
    );
  }
}
