import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isUploading = false;
  String? _currentRecordingPath;

  // Recording timer
  int _recordSeconds = 0;
  Timer? _recordTimer;

  // Playback state
  String? _playingId;

  // Pulse animation for recording indicator
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    _recordTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ─── RECORDING ────────────────────────────────────────────
  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _showSnack('Microphone permission denied');
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/rec_$timestamp.m4a';

    await _recorder.start(const RecordConfig(), path: path);

    _recordSeconds = 0;
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordSeconds++);
    });

    _pulseCtrl.repeat(reverse: true);

    setState(() {
      _isRecording = true;
      _currentRecordingPath = path;
    });
  }

  Future<void> _stopAndSave() async {
    final path = await _recorder.stop();
    _recordTimer?.cancel();
    _pulseCtrl.stop();
    _pulseCtrl.reset();

    setState(() => _isRecording = false);

    if (path == null) return;

    // Ask for a title
    final title = await _showTitleDialog();
    if (title == null) return;

    await _uploadRecording(path, title);
  }

  Future<String?> _showTitleDialog() async {
    final ctrl = TextEditingController(
        text: 'Recording ${DateFormat('MMM d, h:mm a').format(DateTime.now())}');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Recording'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              labelText: 'Title', border: OutlineInputBorder()),
          autofocus: true,
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Discard')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _uploadRecording(String localPath, String title) async {
    setState(() => _isUploading = true);

    try {
      final file = File(localPath);
      final fileName =
          'recordings/$_uid/${DateTime.now().millisecondsSinceEpoch}.m4a';

      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      final duration = _formatDuration(_recordSeconds);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('recordings')
          .add({
        'title': title,
        'url': url,
        'storagePath': fileName,
        'duration': duration,
        'durationSeconds': _recordSeconds,
        'type': 'voice',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSnack('Recording saved!');
    } catch (e) {
      _showSnack('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ─── PLAYBACK ─────────────────────────────────────────────
  Future<void> _playPause(String docId, String url) async {
    if (_playingId == docId) {
      await _player.stop();
      setState(() => _playingId = null);
    } else {
      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
      setState(() => _playingId = docId);
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) setState(() => _playingId = null);
        }
      });
    }
  }

  // ─── DELETE ───────────────────────────────────────────────
  Future<void> _deleteRecording(String docId, String storagePath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recording'),
        content: const Text('This cannot be undone.'),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseStorage.instance.ref().child(storagePath).delete();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('recordings')
          .doc(docId)
          .delete();
      _showSnack('Deleted');
    } catch (e) {
      _showSnack('Failed to delete: $e');
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────
  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text('My Recordings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Record button area ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                // Pulsing mic button
                ScaleTransition(
                  scale: _isRecording ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
                  child: GestureDetector(
                    onTap: _isRecording ? _stopAndSave : _startRecording,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isRecording
                              ? [Colors.red, Colors.red.shade700]
                              : [
                                  const Color(0xFF6C63FF),
                                  const Color(0xFF00D4FF)
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording
                                    ? Colors.red
                                    : const Color(0xFF6C63FF))
                                .withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Timer / prompt
                Text(
                  _isRecording
                      ? _formatDuration(_recordSeconds)
                      : 'Tap to Record',
                  style: TextStyle(
                    fontSize: _isRecording ? 28 : 16,
                    fontWeight: FontWeight.bold,
                    color: _isRecording
                        ? Colors.red
                        : (isDark ? Colors.white60 : Colors.grey[600]),
                  ),
                ),

                if (_isRecording)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('Tap to stop & save',
                        style: TextStyle(
                            color: Colors.red, fontSize: 13)),
                  ),

                if (_isUploading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Saving recording...',
                            style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const Divider(),

          // ── Recordings list ────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_uid)
                  .collection('recordings')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mic_none_rounded,
                            size: 64,
                            color: isDark
                                ? Colors.white24
                                : Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No recordings yet',
                          style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data =
                        doc.data() as Map<String, dynamic>;
                    final docId = doc.id;
                    final title =
                        data['title']?.toString() ?? 'Recording';
                    final duration =
                        data['duration']?.toString() ?? '00:00';
                    final url = data['url']?.toString() ?? '';
                    final storagePath =
                        data['storagePath']?.toString() ?? '';
                    final createdAt =
                        (data['createdAt'] as Timestamp?)?.toDate();
                    final isPlaying = _playingId == docId;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: GestureDetector(
                          onTap: () => _playPause(docId, url),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6C63FF),
                                  Color(0xFF00D4FF)
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '🎙 $duration${createdAt != null ? '  •  ${DateFormat('MMM d, h:mm a').format(createdAt)}' : ''}',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey[600]),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () =>
                              _deleteRecording(docId, storagePath),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}