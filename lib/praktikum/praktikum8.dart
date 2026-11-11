import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../firebase_options.dart';
import '../firebase_messaging_service.dart';

class Praktikum8 extends StatefulWidget {
  const Praktikum8({super.key});

  @override
  State<Praktikum8> createState() => _Praktikum8State();
}

class _Praktikum8State extends State<Praktikum8> {
  final FirebaseMessagingService _messagingService =
      FirebaseMessagingService.instance;
  final List<RemoteMessage> _messages = [];

  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<Object>? _errorSubscription;
  StreamSubscription<String>? _registrationSubscription;
  String _permissionStatus = 'Memeriksa izin...';
  String? _installationId;
  String? _errorMessage;
  String _receiveStatus = 'Listener aktif; menunggu pesan FCM.';
  DateTime? _lastReceivedAt;
  bool _isRegistering = false;

  bool get _hasPermission =>
      _permissionStatus == 'Diizinkan' ||
      _permissionStatus == 'Diizinkan sementara';

  @override
  void initState() {
    super.initState();
    try {
      _messages.addAll(_messagingService.recentMessages);
      _messageSubscription = _messagingService.receivedMessages.listen(
        _addMessage,
      );
      _errorSubscription = _messagingService.errors.listen(_showStreamError);
      _registrationSubscription = _messagingService.onRegistered.listen((
        installationId,
      ) {
        if (!mounted) return;
        setState(() {
          _installationId = installationId;
        });
      }, onError: _showStreamError);
    } catch (error) {
      _errorMessage = 'Tidak dapat memulai Firebase Messaging: $error';
    }
    if (_messagingService.initializationError case final error?) {
      _errorMessage = error;
    }
    unawaited(_loadInitialState());
  }

  Future<void> _loadInitialState() async {
    try {
      final settings = await _messagingService.getNotificationSettings();
      if (!mounted) return;

      setState(() {
        _permissionStatus = _permissionLabel(settings.authorizationStatus);
      });

      if (_hasPermission) {
        await _registerDevice();
      }

      final initialMessage = await _messagingService.getInitialMessage();
      if (initialMessage != null) {
        _messagingService.recordOpenedMessage(initialMessage);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _permissionStatus = 'Firebase belum siap';
        _errorMessage = 'Tidak dapat memeriksa Firebase Messaging: $error';
      });
    }
  }

  Future<void> _enableNotifications() async {
    setState(() {
      _isRegistering = true;
      _errorMessage = null;
    });

    try {
      final settings = await _messagingService.requestPermission();
      if (!mounted) return;

      setState(() {
        _permissionStatus = _permissionLabel(settings.authorizationStatus);
      });

      if (!_hasPermission) {
        setState(() {
          _errorMessage =
              'Izin notifikasi belum diberikan. Aktifkan izin aplikasi '
              'Realtime Communication di pengaturan Android.';
        });
        return;
      }

      await _registerDevice();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal mendaftarkan perangkat ke FCM: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  Future<void> _registerDevice() async {
    final installationId = await _messagingService.register();
    if (!mounted) return;
    setState(() {
      _installationId = installationId;
    });
  }

  void _addMessage(RemoteMessage message) {
    if (!mounted) return;
    setState(() {
      _messages.insert(0, message);
      _lastReceivedAt = DateTime.now();
      _receiveStatus = message.messageId == null
          ? 'Pesan FCM diterima.'
          : 'Pesan FCM diterima (${message.messageId}).';
    });
  }

  void _showStreamError(Object error) {
    if (!mounted) return;
    setState(() {
      _errorMessage = 'Gagal menerima pembaruan Firebase: $error';
    });
  }

  String _permissionLabel(AuthorizationStatus status) {
    return switch (status) {
      AuthorizationStatus.authorized => 'Diizinkan',
      AuthorizationStatus.provisional => 'Diizinkan sementara',
      AuthorizationStatus.denied => 'Ditolak',
      AuthorizationStatus.deniedPermanently => 'Ditolak permanen',
      AuthorizationStatus.notDetermined => 'Belum diminta',
    };
  }

  Future<void> _copyInstallationId() async {
    final installationId = _installationId;
    if (installationId == null) return;

    await Clipboard.setData(ClipboardData(text: installationId));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Installation ID disalin')));
  }

  @override
  void dispose() {
    unawaited(_messageSubscription?.cancel());
    unawaited(_errorSubscription?.cancel());
    unawaited(_registrationSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Praktikum 8 - Firebase FCM'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Push Notification',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aktifkan izin notifikasi untuk mendaftarkan perangkat ke Firebase '
            'Cloud Messaging. Salin Firebase Installation ID (FID) sebagai '
            'target pengiriman langsung FCM. Jika Firebase Console menyimpan '
            'beberapa ID, pilih yang sama persis dengan FID aktif di bawah.',
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud),
              title: const Text('Project Firebase'),
              subtitle: Text(DefaultFirebaseOptions.currentPlatform.projectId),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.notifications_active,
                color: _hasPermission ? Colors.green : Colors.orange,
              ),
              title: const Text('Izin notifikasi'),
              subtitle: Text(_permissionStatus),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _isRegistering ? null : _enableNotifications,
            icon: _isRegistering
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.app_registration),
            label: Text(
              _isRegistering ? 'Mendaftarkan...' : 'Aktifkan & Daftarkan FCM',
            ),
          ),
          if (_installationId != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Firebase Installation ID (FID)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Salin Installation ID',
                          onPressed: _copyInstallationId,
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                    SelectableText(_installationId!),
                  ],
                ),
              ),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          Text(
            'Pesan diterima (${_messages.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(
                _messages.isEmpty ? Icons.hourglass_top : Icons.mark_email_read,
                color: _messages.isEmpty ? Colors.orange : Colors.green,
              ),
              title: const Text('Status penerimaan FCM'),
              subtitle: Text(
                _lastReceivedAt == null
                    ? _receiveStatus
                    : '$_receiveStatus\n'
                          'Waktu: ${_lastReceivedAt!.toLocal()}',
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_messages.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.mark_email_unread),
                title: Text('Belum ada pesan'),
                subtitle: Text(
                  'Kirim pesan uji ke FID dari Firebase Cloud Messaging. '
                  'Saat aplikasi terbuka, notifikasi muncul di Android dan '
                  'pesan tercatat di halaman ini.',
                ),
              ),
            )
          else
            ..._messages.map(_messageCard),
        ],
      ),
    );
  }

  Widget _messageCard(RemoteMessage message) {
    final notification = message.notification;
    final dataText = message.data.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');

    return Card(
      child: ListTile(
        leading: const Icon(Icons.notifications, color: Colors.blue),
        title: Text(notification?.title ?? 'Pesan data FCM'),
        subtitle: Text(
          [
            ?notification?.body,
            if (dataText.isNotEmpty) dataText,
            if (message.messageId != null) 'ID: ${message.messageId}',
          ].join('\n'),
        ),
      ),
    );
  }
}
