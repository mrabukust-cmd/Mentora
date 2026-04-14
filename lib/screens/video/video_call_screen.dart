import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mentora/services/agora_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String callId;
  final String channelName;
  final String currentUserId;
  final String otherUserName;
  final bool isCaller;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.channelName,
    required this.currentUserId,
    required this.otherUserName,
    required this.isCaller,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late final RtcEngine _engine;

  bool _localUserJoined = false;
  bool _remoteUserJoined = false;
  int? _remoteUid;
  bool _muted = false;
  bool _cameraOff = false;
  bool _speakerOn = true;
  bool _isInitialized = false;

  // Call timer
  int _callSeconds = 0;
  Timer? _callTimer;

  // Listen for remote hang-up
  StreamSubscription? _callStatusSub;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _listenForCallEnd();
  }

  Future<void> _initAgora() async {
    // Request permissions
    await [Permission.microphone, Permission.camera].request();

    // Create engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: AgoraService.agoraAppId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // Register event handlers
    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        if (mounted) setState(() => _localUserJoined = true);
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        if (mounted) {
          setState(() {
            _remoteUid = remoteUid;
            _remoteUserJoined = true;
          });
          _startTimer();
        }
      },
      onUserOffline: (connection, remoteUid, reason) {
        if (mounted) {
          setState(() {
            _remoteUid = null;
            _remoteUserJoined = false;
          });
          _endCall();
        }
      },
      onError: (err, msg) {
        debugPrint('Agora error: $err - $msg');
      },
    ));

    await _engine.enableVideo();
    await _engine.enableAudio();
    await _engine.setDefaultAudioRouteToSpeakerphone(true);
    await _engine.startPreview();

    // Join channel
    await _engine.joinChannel(
      token: AgoraService.agoraTempToken,
      channelId: widget.channelName,
      uid: 0, // Agora auto-assigns UID
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );

    if (mounted) setState(() => _isInitialized = true);
  }

  void _listenForCallEnd() {
    _callStatusSub = AgoraService()
        .callStatusStream(widget.callId)
        .listen((status) {
      if (status == 'ended' || status == 'declined') {
        if (mounted) _endCall(remote: true);
      }
    });
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callSeconds++);
    });
  }

  String get _callDuration {
    final m = (_callSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_callSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _toggleMute() async {
    setState(() => _muted = !_muted);
    await _engine.muteLocalAudioStream(_muted);
  }

  Future<void> _toggleCamera() async {
    setState(() => _cameraOff = !_cameraOff);
    await _engine.muteLocalVideoStream(_cameraOff);
  }

  Future<void> _toggleSpeaker() async {
    setState(() => _speakerOn = !_speakerOn);
    await _engine.setDefaultAudioRouteToSpeakerphone(_speakerOn);
  }

  Future<void> _switchCamera() async {
    await _engine.switchCamera();
  }

  Future<void> _endCall({bool remote = false}) async {
    _callTimer?.cancel();
    _callStatusSub?.cancel();

    if (!remote) {
      await AgoraService().endCall(widget.callId);
    }

    await _engine.leaveChannel();
    await _engine.release();

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _callStatusSub?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Remote video (full screen) ─────────────────────
          if (_remoteUserJoined && _remoteUid != null)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine,
                canvas: VideoCanvas(uid: _remoteUid),
                connection:
                    RtcConnection(channelId: widget.channelName),
              ),
            )
          else
            _buildWaitingScreen(),

          // ── Local video (small, corner) ────────────────────
          if (_localUserJoined && !_cameraOff)
            Positioned(
              top: 60,
              right: 16,
              child: Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                clipBehavior: Clip.hardEdge,
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              ),
            ),

          // ── Top bar ────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Text(
                        widget.otherUserName.isNotEmpty
                            ? widget.otherUserName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.otherUserName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _remoteUserJoined
                                ? _callDuration
                                : 'Calling...',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    // Switch camera
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios,
                          color: Colors.white),
                      onPressed: _switchCamera,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom controls ────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 24, horizontal: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ControlButton(
                      icon: _muted ? Icons.mic_off : Icons.mic,
                      label: _muted ? 'Unmute' : 'Mute',
                      onTap: _toggleMute,
                      active: _muted,
                    ),
                    _ControlButton(
                      icon: _cameraOff
                          ? Icons.videocam_off
                          : Icons.videocam,
                      label: _cameraOff ? 'Cam Off' : 'Camera',
                      onTap: _toggleCamera,
                      active: _cameraOff,
                    ),
                    _ControlButton(
                      icon: _speakerOn ? Icons.volume_up : Icons.hearing,
                      label: _speakerOn ? 'Speaker' : 'Earpiece',
                      onTap: _toggleSpeaker,
                    ),
                    // End call button
                    GestureDetector(
                      onTap: () => _endCall(),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call_end,
                            color: Colors.white, size: 30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Initializing overlay
          if (!_isInitialized)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
              child: Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.otherUserName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              widget.isCaller ? 'Calling...' : 'Connecting...',
              style:
                  const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                  color: Color(0xFF6C63FF), strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}