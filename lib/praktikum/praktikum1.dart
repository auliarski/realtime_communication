
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class Praktikum1 extends StatefulWidget {
  const Praktikum1({super.key});

  @override
  State<Praktikum1> createState() => _Praktikum1State();
}

class _Praktikum1State extends State<Praktikum1> {
  final TextEditingController _nameController =
      TextEditingController();

  List<dynamic> _data = [];

  bool _isLoading = false;
  String _status = 'Belum terhubung ke server';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // GET: Mengambil data dari server
  Future<void> fetchData() async {
    setState(() {
      _isLoading = true;
      _status = 'Mengambil data...';
    });

    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.dataEndpoint),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        setState(() {
          _data = result is List
              ? result
              : result['data'] ?? [];

          _status = 'Berhasil terhubung ke server';
        });
      } else {
        setState(() {
          _status =
              'Gagal mengambil data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Koneksi gagal: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // POST: Mengirim data ke server
  Future<void> sendData() async {
    final name = _nameController.text.trim();
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (name.isEmpty) {
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Nama tidak boleh kosong!'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.dataEndpoint),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'name': name,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        _nameController.clear();

        if (mounted) {
          messenger?.showSnackBar(
            const SnackBar(
              content: Text('Data berhasil dikirim!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        await fetchData();
      } else {
        setState(() {
          _status =
              'Gagal mengirim data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Gagal mengirim data: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Praktikum 1 - REST API'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : fetchData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh data',
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status koneksi
            Card(
              child: ListTile(
                leading: Icon(
                  _status.contains('Berhasil')
                      ? Icons.check_circle
                      : Icons.info,
                  color: _status.contains('Berhasil')
                      ? Colors.green
                      : Colors.orange,
                ),
                title: const Text('Status Server'),
                subtitle: Text(_status),
              ),
            ),

            const SizedBox(height: 20),

            // Form POST
            const Text(
              'Kirim Data (POST)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama',
                hintText: 'Masukkan nama',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : sendData,
                icon: const Icon(Icons.send),
                label: const Text('Kirim Data'),
              ),
            ),

            const Divider(height: 35),

            // Data GET
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Data dari Server (GET)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('${_data.length} data'),
              ],
            ),

            const SizedBox(height: 10),

            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_data.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Belum ada data atau data gagal dimuat.',
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _data.length,
                  itemBuilder: (context, index) {
                    final item = _data[index];

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          item is Map
                              ? '${item['name'] ?? item['nama'] ?? 'Tanpa nama'}'
                              : '$item',
                        ),
                        subtitle: item is Map
                            ? Text(
                                'ID: ${item['id'] ?? '-'}',
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
