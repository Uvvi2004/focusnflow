import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PomodoroScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const PomodoroScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const _bgColor = Color(0xFF0F1117);
  static const _cardColor = Color(0xFF1A1D2E);
  static const _accentColor = Color(0xFF4F8EF7);
  static const _textColor = Color(0xFFE8EAED);
  static const _subtextColor = Color(0xFF9AA0A6);

  Timer? _localTimer;
  int _secondsLeft = 25 * 60;
  bool _isRunning = false;
  String _mode = 'focus'; // focus / break

  @override
  void initState() {
    super.initState();
    _listenToFirestore();
  }

  void _listenToFirestore() {
    FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final timer = data['pomodoroTimer'] as Map<String, dynamic>?;
      if (timer == null) return;

      final running = timer['isRunning'] as bool? ?? false;
      final seconds = timer['secondsLeft'] as int? ?? 25 * 60;
      final mode = timer['mode'] as String? ?? 'focus';

      if (mounted) {
        setState(() {
          _isRunning = running;
          _secondsLeft = seconds;
          _mode = mode;
        });

        if (running) {
          _startLocalTimer();
        } else {
          _localTimer?.cancel();
        }
      }
    });
  }

  void _startLocalTimer() {
    _localTimer?.cancel();
    _localTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _localTimer?.cancel();
        setState(() {
          _isRunning = false;
          _mode = _mode == 'focus' ? 'break' : 'focus';
          _secondsLeft = _mode == 'focus' ? 25 * 60 : 5 * 60;
        });
        _updateFirestore(false);
      }
    });
  }

  Future<void> _updateFirestore(bool running) async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .set({
      'pomodoroTimer': {
        'isRunning': running,
        'secondsLeft': _secondsLeft,
        'mode': _mode,
        'updatedAt': Timestamp.now(),
      }
    }, SetOptions(merge: true));
  }

  void _toggleTimer() {
    final newRunning = !_isRunning;
    setState(() => _isRunning = newRunning);
    _updateFirestore(newRunning);
    if (newRunning) {
      _startLocalTimer();
    } else {
      _localTimer?.cancel();
    }
  }

  void _resetTimer() {
    _localTimer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsLeft = _mode == 'focus' ? 25 * 60 : 5 * 60;
    });
    _updateFirestore(false);
  }

  void _switchMode(String mode) {
    _localTimer?.cancel();
    setState(() {
      _mode = mode;
      _isRunning = false;
      _secondsLeft = mode == 'focus' ? 25 * 60 : 5 * 60;
    });
    _updateFirestore(false);
  }

  String get _timeString {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress {
    final total = _mode == 'focus' ? 25 * 60 : 5 * 60;
    return 1 - (_secondsLeft / total);
  }

  @override
  void dispose() {
    _localTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modeColor = _mode == 'focus' ? _accentColor : Colors.greenAccent;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.groupName,
              style: const TextStyle(
                  color: _textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const Text(
              'Shared Pomodoro Timer',
              style: TextStyle(color: _subtextColor, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Mode selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _ModeButton(
                    label: 'Focus',
                    selected: _mode == 'focus',
                    onTap: () => _switchMode('focus'),
                  ),
                  _ModeButton(
                    label: 'Break',
                    selected: _mode == 'break',
                    onTap: () => _switchMode('break'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // Timer circle
            SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white10,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(modeColor),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _timeString,
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: modeColor,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _mode == 'focus' ? 'Focus Session' : 'Break Time',
                        style: const TextStyle(
                            color: _subtextColor, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // Sync note
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: modeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: modeColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sync_rounded, color: modeColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Synced with all group members in real time',
                    style: TextStyle(color: modeColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset
                GestureDetector(
                  onTap: _resetTimer,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: _subtextColor, size: 24),
                  ),
                ),
                const SizedBox(width: 24),

                // Play/Pause
                GestureDetector(
                  onTap: _toggleTimer,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: modeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: modeColor.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 24),

                // Skip
                GestureDetector(
                  onTap: () =>
                      _switchMode(_mode == 'focus' ? 'break' : 'focus'),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Icon(Icons.skip_next_rounded,
                        color: _subtextColor, size: 24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const _accentColor = Color(0xFF4F8EF7);
  static const _subtextColor = Color(0xFF9AA0A6);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : _subtextColor,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}