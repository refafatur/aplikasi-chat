import 'package:flutter/material.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';

class CallVoicePage extends StatefulWidget {
  final String contactName;
  final String phoneNumber;
  final String callLogId;

  const CallVoicePage({
    Key? key,
    required this.contactName, 
    required this.phoneNumber,
    required this.callLogId,
  }) : super(key: key);

  @override
  _CallVoicePageState createState() => _CallVoicePageState();
}

class _CallVoicePageState extends State<CallVoicePage> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  String _callDuration = '00:00';
  Timer? _timer;
  bool _isCallActive = false;
  FlutterSoundPlayer? _audioPlayer;
  int _seconds = 0;
  late FlutterSoundPlayer _ringtonePlayer;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _initPlayer();
    _playRingtone();
    _acceptCall();
  }

  Future<void> _initPlayer() async {
    _audioPlayer = FlutterSoundPlayer();
    await _audioPlayer!.openPlayer();
    await _audioPlayer!.setSubscriptionDuration(const Duration(milliseconds: 100));
  }

  Future<void> _checkPermissions() async {
    final micStatus = await Permission.microphone.request();
    final phoneStatus = await Permission.phone.request();
    
    if (micStatus.isGranted && phoneStatus.isGranted) {
      _startTimer();
      _acceptCall();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin mikrofon dan telepon diperlukan untuk panggilan suara')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _playRingtone() async {
    _ringtonePlayer = FlutterSoundPlayer();
    await _ringtonePlayer.openPlayer();
    await _ringtonePlayer.startPlayer(fromURI: 'path/to/ringtone.mp3');
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isCallActive && mounted) {
        setState(() {
          _seconds++;
          _callDuration = 
            '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';
        });
      }
    });
  }

  void _acceptCall() {
    setState(() {
      _isCallActive = true;
    });
    _ringtonePlayer.stopPlayer();
  }

  @override
  void dispose() async {
    _timer?.cancel();
    await _audioPlayer?.closePlayer();
    await _ringtonePlayer.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50),
            Text(
              widget.contactName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _callDuration,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 20
              ),
            ),
            const Spacer(),
            const CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/person.jpg'),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                      color: _isSpeakerOn ? Colors.blue : Colors.white,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSpeakerOn = !_isSpeakerOn;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.blue : Colors.white,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        _isMuted = !_isMuted;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              width: 65,
              height: 65,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}