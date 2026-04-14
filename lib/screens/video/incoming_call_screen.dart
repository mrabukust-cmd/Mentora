import 'package:flutter/material.dart';
import 'package:mentora/services/agora_service.dart';
import 'package:mentora/screens/video/video_call_screen.dart';

/// Full-screen incoming call UI shown when someone calls you.
class IncomingCallScreen extends StatelessWidget {
  final String callId;
  final String callerName;
  final String channelName;
  final String currentUserId;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.callerName,
    required this.channelName,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF6C63FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              // Caller avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 3),
                  color: Colors.white.withOpacity(0.1),
                ),
                child: Center(
                  child: Text(
                    callerName.isNotEmpty ? callerName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 56,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                callerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Incoming Video Call',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),

              const Spacer(),

              // Ringing animation dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return _PulsingDot(delay: Duration(milliseconds: i * 300));
                }),
              ),

              const Spacer(),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 48, vertical: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Decline
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await AgoraService().declineCall(callId);
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call_end,
                                color: Colors.white, size: 32),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('Decline',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),

                    // Accept
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await AgoraService().acceptCall(callId);
                            if (!context.mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VideoCallScreen(
                                  callId: callId,
                                  channelName: channelName,
                                  currentUserId: currentUserId,
                                  otherUserName: callerName,
                                  isCaller: false,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1DD1A1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.videocam,
                                color: Colors.white, size: 32),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('Accept',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Duration delay;
  const _PulsingDot({required this.delay});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: const BoxDecoration(
            color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }
}