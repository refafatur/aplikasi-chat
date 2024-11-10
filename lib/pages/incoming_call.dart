import 'package:flutter/material.dart';
import 'call_voice.dart';
import 'package:permission_handler/permission_handler.dart';

class IncomingCallPage extends StatelessWidget {
  final String callerName;
  final String callerNumber;

  const IncomingCallPage({
    Key? key,
    required this.callerName, 
    required this.callerNumber,
  }) : super(key: key);

  Future<void> _requestMicrophonePermission(BuildContext context) async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _acceptCall(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izin mikrofon diperlukan untuk melakukan panggilan'),
        ),
      );
    }
  }

  void _acceptCall(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallVoicePage(
          contactName: callerName,
          phoneNumber: callerNumber,
          callLogId: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.call,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            Text(
              'Panggilan dari:',
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
            Text(
              callerName,
              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
            ),
            Text(
              callerNumber,
              style: const TextStyle(color: Colors.white70, fontSize: 20),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _requestMicrophonePermission(context);
                  },
                  child: const Text('Terima'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Tolak'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}