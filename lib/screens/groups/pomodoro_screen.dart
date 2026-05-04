import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Shared Pomodoro timer synced across all group members via Firestore.
//
// Instead of storing secondsLeft and decrementing locally (which causes drift
// between devices), we store endsAt — the absolute timestamp when the session ends.
// Each device computes remaining = endsAt - now, so everyone sees the same number.
//
// Firestore shape (inside groups/{groupId}.pomodoroTimer):
//   mode            : 'focus' | 'break'
//   totalSeconds    : int    — full duration for the progress ring
//   secondsRemaining: int    — saved when paused
//   endsAt          : Timestamp? — null = paused, non-null = running
class PomodoroScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const PomodoroScreen({super.key, required this.groupId, required this.groupName});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const _bgColor = Color(0xFF0F1117);
  static const _cardColor = Color(0xFF1A1D2E);
  static const _accentColor = Color(0xFF4F8EF7);
  static const _textColor = Color(0xFFE8EAED);
  static const _subtextColor = Color(0xFF9AA0A6);

  DateTime? _endsAt;           // null when paused
  int _secondsRemaining = 25 * 60;
  int _totalSeconds = 25 * 60; // full duration for the current mode
  String _mode = 'focus';

  // Guard so the expiration write fires only once — without it _tick() could
  // write multiple times before the Firestore snapshot comes back.
  bool _writingExpiration = false;

  Timer? _ticker;
  StreamSubscription<DocumentSnapshot>? _firestoreSub;

  bool get _isRunning => _endsAt != null;

  // When running: compute from endsAt so all devices stay in sync.
  // When paused: use the saved secondsRemaining.
  int get _displaySeconds {
    if (_endsAt == null) return _secondsRemaining;
    final diff = _endsAt!.difference(DateTime.now()).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  double get _progress =>
      _totalSeconds == 0 ? 0 : 1 - (_displaySeconds / _totalSeconds);

  String get _timeString {
    final s = _displaySeconds;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    // Listen to the group doc so any member's action updates everyone's screen
    _firestoreSub = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .snapshots()
        .listen(_onSnapshot);

    // Local ticker just redraws the countdown — Firestore is the source of truth
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  // Sync all timer state from Firestore whenever the document changes
  void _onSnapshot(DocumentSnapshot snap) {
    if (!snap.exists || !mounted) return;
    final data = snap.data() as Map<String, dynamic>;
    final timer = data['pomodoroTimer'] as Map<String, dynamic>?;
    if (timer == null) return;

    final ts = timer['endsAt'] as Timestamp?;

    setState(() {
      _mode = (timer['mode'] as String?) ?? 'focus';
      // Always update totalSeconds so reset uses the right duration for the current mode
      _totalSeconds = (timer['totalSeconds'] as int?) ??
          (_mode == 'focus' ? 25 * 60 : 5 * 60);
      _secondsRemaining = (timer['secondsRemaining'] as int?) ?? _totalSeconds;
      _endsAt = ts?.toDate();
      _writingExpiration = false;
    });
  }

  void _tick() {
    if (!mounted || _endsAt == null) return;

    if (_displaySeconds <= 0 && !_writingExpiration) {
      // Timer expired — flip mode and pause for all members
      _writingExpiration = true;
      final nextMode = _mode == 'focus' ? 'break' : 'focus';
      final nextTotal = nextMode == 'focus' ? 25 * 60 : 5 * 60;
      _writeState(mode: nextMode, totalSeconds: nextTotal, secondsRemaining: nextTotal, endsAt: null);
    } else {
      setState(() {}); // redraw the clock
    }
  }

  // All interactions go through a single write so the Firestore shape stays consistent
  Future<void> _writeState({
    required String mode,
    required int totalSeconds,
    required int secondsRemaining,
    required DateTime? endsAt,
  }) {
    return FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .set({
      'pomodoroTimer': {
        'mode': mode,
        'totalSeconds': totalSeconds,
        'secondsRemaining': secondsRemaining,
        'endsAt': endsAt != null ? Timestamp.fromDate(endsAt) : null,
        'updatedAt': Timestamp.now(),
      }
    }, SetOptions(merge: true));
  }

  void _toggleTimer() {
    if (_isRunning) {
      // Pause — save current remaining seconds and clear endsAt
      _writeState(
        mode: _mode, totalSeconds: _totalSeconds,
        secondsRemaining: _displaySeconds, endsAt: null,
      );
    } else {
      // Start/resume — pin the absolute end time so every device computes the same value
      _writeState(
        mode: _mode, totalSeconds: _totalSeconds,
        secondsRemaining: _secondsRemaining,
        endsAt: DateTime.now().add(Duration(seconds: _secondsRemaining)),
      );
    }
  }

  void _resetTimer() => _writeState(
      mode: _mode, totalSeconds: _totalSeconds,
      secondsRemaining: _totalSeconds, endsAt: null);

  void _switchMode(String mode) {
    final total = mode == 'focus' ? 25 * 60 : 5 * 60;
    _writeState(mode: mode, totalSeconds: total, secondsRemaining: total, endsAt: null);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _firestoreSub?.cancel();
    // Pause when the user navigates away so the group sees accurate remaining time
    if (_isRunning) {
      _writeState(
        mode: _mode, totalSeconds: _totalSeconds,
        secondsRemaining: _displaySeconds, endsAt: null,
      );
    }
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
            Text(widget.groupName,
                style: const TextStyle(
                    color: _textColor, fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('Shared Pomodoro Timer',
                style: TextStyle(color: _subtextColor, fontSize: 12)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Focus / Break mode selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: _cardColor, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  _ModeButton(
                      label: 'Focus', selected: _mode == 'focus',
                      onTap: () => _switchMode('focus')),
                  _ModeButton(
                      label: 'Break', selected: _mode == 'break',
                      onTap: () => _switchMode('break')),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // Timer ring — progress driven by _progress, time string redrawn every second
            SizedBox(
              width: 240, height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 240, height: 240,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(modeColor),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_timeString,
                          style: TextStyle(
                              fontSize: 56, fontWeight: FontWeight.bold,
                              color: modeColor, letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text(_mode == 'focus' ? 'Focus Session' : 'Break Time',
                          style: const TextStyle(color: _subtextColor, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // Sync indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: modeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: modeColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sync_rounded, color: modeColor, size: 16),
                  const SizedBox(width: 8),
                  Text('Synced with all group members in real time',
                      style: TextStyle(color: modeColor, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Reset | Play/Pause | Skip
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CircleButton(
                    icon: Icons.refresh_rounded, color: _subtextColor,
                    size: 56, onTap: _resetTimer),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: _toggleTimer,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: modeColor, shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: modeColor.withValues(alpha: 0.4),
                            blurRadius: 20, spreadRadius: 2)
                      ],
                    ),
                    child: Icon(
                      _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white, size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                _CircleButton(
                    icon: Icons.skip_next_rounded, color: _subtextColor,
                    size: 56,
                    onTap: () => _switchMode(_mode == 'focus' ? 'break' : 'focus')),
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

  const _ModeButton({required this.label, required this.selected, required this.onTap});

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
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: selected ? Colors.white : _subtextColor,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14)),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _CircleButton(
      {required this.icon, required this.color, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
