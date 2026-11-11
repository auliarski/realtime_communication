import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum WebRTCRole { caller, callee }

class WebRTCService {
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  String roomId = '';
  WebRTCRole role = WebRTCRole.caller;

  bool microphoneEnabled = true;
  bool cameraEnabled = true;

  Function(String)? onStatus;
  Function(bool)? onCallState;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _signalSubscription;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool _renderersInitialized = false;
  bool _joined = false;
  final List<RTCIceCandidate> _pendingCandidates = [];

  Future<void> initialize({
    required String room,
    required WebRTCRole userRole,
    required Function(String) statusCallback,
    required Function(bool) callStateCallback,
  }) async {
    if (_joined) {
      throw StateError('WebRTC sudah terhubung ke sebuah room');
    }

    roomId = room;
    role = userRole;
    onStatus = statusCallback;
    onCallState = callStateCallback;

    try {
      if (!_renderersInitialized) {
        await localRenderer.initialize();
        await remoteRenderer.initialize();
        _renderersInitialized = true;
      }

      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': microphoneEnabled,
        'video': cameraEnabled,
      });
      localRenderer.srcObject = _localStream;

      final signalingUrl = Uri(
        scheme: Uri.base.scheme == 'https' ? 'wss' : 'ws',
        host: Uri.base.host.isEmpty ? 'localhost' : Uri.base.host,
        port: 3000,
      );
      final channel = WebSocketChannel.connect(signalingUrl);
      _channel = channel;
      await channel.ready;

      _signalSubscription = channel.stream.listen(
        (dynamic rawMessage) {
          unawaited(_handleSignalMessage(rawMessage));
        },
        onError: (Object error) {
          unawaited(_endAfterSignalFailure('Koneksi signaling gagal: $error'));
        },
        onDone: () {
          if (identical(_channel, channel)) {
            unawaited(_endAfterSignalFailure('Koneksi signaling terputus'));
          }
        },
      );

      _sendSignal({'type': 'join', 'room': roomId, 'role': role.name});
      _setStatus('Menghubungkan ke room...');
    } catch (error) {
      await _endAfterSignalFailure('Gagal memulai WebRTC: $error');
      rethrow;
    }
  }

  Future<void> _handleSignalMessage(dynamic rawMessage) async {
    try {
      final decoded = jsonDecode(rawMessage as String);
      if (decoded is! Map) {
        throw const FormatException('Pesan signaling harus berupa object');
      }
      final message = Map<String, dynamic>.from(decoded);

      switch (message['type']) {
        case 'joined':
          _joined = true;
          _setCallState(true);
          if (message['peerPresent'] == true && role == WebRTCRole.caller) {
            await _createAndSendOffer();
          } else {
            _setStatus(
              message['peerPresent'] == true
                  ? 'Room terhubung; menunggu offer dari caller...'
                  : 'Room siap; menunggu peserta lain...',
            );
          }
        case 'peer-joined':
          if (role == WebRTCRole.caller) {
            await _createAndSendOffer();
          } else {
            _setStatus('Peserta lain bergabung; menunggu offer...');
          }
        case 'offer':
          await _acceptOffer(message);
        case 'answer':
          await _acceptAnswer(message);
        case 'candidate':
          await _acceptCandidate(message);
        case 'peer-left':
          await _closePeerConnection();
          remoteRenderer.srcObject = null;
          _setStatus('Peserta lain terputus dari room');
        case 'error':
          final detail = message['message'] ?? 'terjadi kesalahan';
          await _endAfterSignalFailure('Signaling: $detail');
          _setStatus('Signaling: $detail');
        default:
          throw FormatException(
            'Jenis pesan signaling tidak dikenal: ${message['type']}',
          );
      }
    } catch (error) {
      _setStatus('Gagal memproses pesan signaling: $error');
    }
  }

  Future<RTCPeerConnection> _ensurePeerConnection() async {
    final existing = _peerConnection;
    if (existing != null) return existing;

    final peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    });
    _peerConnection = peerConnection;

    final localStream = _localStream;
    if (localStream == null) {
      throw StateError('Media lokal belum tersedia');
    }
    for (final track in localStream.getTracks()) {
      await peerConnection.addTrack(track, localStream);
    }

    peerConnection.onIceCandidate = (candidate) {
      if (candidate.candidate != null && _channel != null && _joined) {
        _sendSignal({'type': 'candidate', 'candidate': candidate.toMap()});
      }
    };
    peerConnection.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
        _setStatus('Media peserta lain diterima');
      }
    };
    peerConnection.onConnectionState = (state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _setCallState(true);
          _setStatus('Panggilan WebRTC terhubung');
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          _setStatus('Koneksi peer terputus sementara');
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _setStatus('Koneksi peer gagal');
        default:
          break;
      }
    };
    return peerConnection;
  }

  Future<void> _createAndSendOffer() async {
    final peerConnection = await _ensurePeerConnection();
    final offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);
    _sendSignal({'type': 'offer', 'description': offer.toMap()});
    _setStatus('Offer dikirim; menunggu jawaban...');
  }

  Future<void> _acceptOffer(Map<String, dynamic> message) async {
    final description = _readDescription(message['description']);
    final peerConnection = await _ensurePeerConnection();
    await peerConnection.setRemoteDescription(description);
    await _flushPendingCandidates(peerConnection);

    final answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);
    _sendSignal({'type': 'answer', 'description': answer.toMap()});
    _setStatus('Answer dikirim; menghubungkan panggilan...');
  }

  Future<void> _acceptAnswer(Map<String, dynamic> message) async {
    final description = _readDescription(message['description']);
    final peerConnection = _peerConnection;
    if (peerConnection == null) {
      throw StateError('Menerima answer sebelum offer dibuat');
    }
    await peerConnection.setRemoteDescription(description);
    await _flushPendingCandidates(peerConnection);
    _setStatus('Answer diterima; menghubungkan panggilan...');
  }

  Future<void> _acceptCandidate(Map<String, dynamic> message) async {
    final candidateData = message['candidate'];
    if (candidateData is! Map) {
      throw const FormatException('ICE candidate tidak valid');
    }
    final values = Map<String, dynamic>.from(candidateData);
    final candidate = RTCIceCandidate(
      values['candidate'] as String?,
      values['sdpMid'] as String?,
      values['sdpMLineIndex'] as int?,
    );
    final peerConnection = _peerConnection;
    if (peerConnection == null ||
        await peerConnection.getRemoteDescription() == null) {
      _pendingCandidates.add(candidate);
      return;
    }
    await peerConnection.addCandidate(candidate);
  }

  RTCSessionDescription _readDescription(dynamic value) {
    if (value is! Map) {
      throw const FormatException('Deskripsi SDP tidak valid');
    }
    final description = Map<String, dynamic>.from(value);
    final sdp = description['sdp'];
    final type = description['type'];
    if (sdp is! String || type is! String) {
      throw const FormatException('Deskripsi SDP tidak lengkap');
    }
    return RTCSessionDescription(sdp, type);
  }

  Future<void> _flushPendingCandidates(RTCPeerConnection peerConnection) async {
    for (final candidate in _pendingCandidates) {
      await peerConnection.addCandidate(candidate);
    }
    _pendingCandidates.clear();
  }

  void _sendSignal(Map<String, dynamic> message) {
    final channel = _channel;
    if (channel == null) {
      throw StateError('Koneksi signaling belum tersedia');
    }
    channel.sink.add(jsonEncode(message));
  }

  void toggleMicrophone(bool enabled) {
    microphoneEnabled = enabled;
    for (final track
        in _localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = enabled;
    }
  }

  void toggleCamera(bool enabled) {
    cameraEnabled = enabled;
    for (final track
        in _localStream?.getVideoTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = enabled;
    }
  }

  Future<void> disconnect() async {
    await _endAfterSignalFailure('Panggilan selesai');
  }

  Future<void> _endAfterSignalFailure(String status) async {
    final channel = _channel;
    _channel = null;
    _joined = false;
    _setCallState(false);

    await _signalSubscription?.cancel();
    _signalSubscription = null;
    await channel?.sink.close();
    await _releaseCallResources();
    if (status.isNotEmpty) _setStatus(status);
  }

  Future<void> _releaseCallResources() async {
    await _closePeerConnection();
    final localStream = _localStream;
    _localStream = null;
    if (localStream != null) {
      for (final track in localStream.getTracks()) {
        await track.stop();
      }
      await localStream.dispose();
    }
    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
  }

  Future<void> _closePeerConnection() async {
    final peerConnection = _peerConnection;
    _peerConnection = null;
    _pendingCandidates.clear();
    await peerConnection?.close();
    await peerConnection?.dispose();
  }

  void _setStatus(String value) => onStatus?.call(value);

  void _setCallState(bool value) => onCallState?.call(value);

  Future<void> dispose() async {
    onStatus = null;
    onCallState = null;
    await disconnect();
    if (_renderersInitialized) {
      await localRenderer.dispose();
      await remoteRenderer.dispose();
      _renderersInitialized = false;
    }
  }
}
