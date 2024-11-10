import 'package:flutter/material.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:flutter_sound/flutter_sound.dart';

class VideoCallPage extends StatefulWidget {
  final String contactName;
  final String phoneNumber;
  final String callLogId;

  const VideoCallPage({
    Key? key,
    required this.contactName,
    required this.phoneNumber,
    required this.callLogId
  }) : super(key: key);

  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = false;
  String _callDuration = '00:00';
  late Timer _timer;
  bool _isCallActive = false;
  CameraController? _cameraController;
  bool _isFrontCamera = true;
  late FlutterSoundPlayer _ringtonePlayer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initCamera();
    _playRingtone();
    _acceptCall();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final camera = _isFrontCamera 
          ? cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.front)
          : cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.back);

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
      );

      try {
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        print('Error initializing camera: $e');
      }
    }
  }

  void _switchCamera() async {
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
    await _cameraController?.dispose();
    await _initCamera();
  }

  void _startTimer() {
    int seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isCallActive) {
        setState(() {
          seconds++;
          _callDuration = 
            '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
        });
      }
    });
  }

  Future<void> _playRingtone() async {
    _ringtonePlayer = FlutterSoundPlayer();
    await _ringtonePlayer.openPlayer();
    await _ringtonePlayer.startPlayer(fromURI: 'path/to/ringtone.mp3');
  }

  void _acceptCall() {
    setState(() {
      _isCallActive = true;
    });
    _ringtonePlayer.stopPlayer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Area video utama (remote video)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[900],
            child: const Center(
              child: Icon(
                Icons.person,
                size: 120,
                color: Colors.white54,
              ),
            ),
          ),

          // Video lokal (kecil di pojok)
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              width: 100,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _cameraController != null && _cameraController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _cameraController!.value.aspectRatio,
                        child: CameraPreview(_cameraController!),
                      )
                    : const Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white54,
                        ),
                      ),
              ),
            ),
          ),

          // Informasi panggilan dan kontrol
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.contactName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _callDuration,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isCameraOff ? Icons.videocam_off : Icons.videocam,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            _isCameraOff = !_isCameraOff;
                            if (_isCameraOff) {
                              _cameraController?.stopImageStream();
                            } else {
                              _initCamera();
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          _isMuted ? Icons.mic_off : Icons.mic,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            _isMuted = !_isMuted;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.call_end,
                          color: Colors.red,
                          size: 40,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSpeakerOn = !_isSpeakerOn;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.switch_camera,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: _switchCamera,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}