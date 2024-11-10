import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:http_parser/http_parser.dart';
import 'video_call.dart';
import 'call_voice.dart';

class ChatDetailPage extends StatefulWidget {
  final String contactName;
  final String no_hp;
  final String receiverNoHp;
  final String callLogId;

  const ChatDetailPage({
    super.key,
    required this.contactName,
    required this.no_hp,
    required this.receiverNoHp,
    required this.callLogId,
  });

  @override
  _ChatDetailPageState createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  List<Map<String, dynamic>> messages = [];
  TextEditingController messageController = TextEditingController();
  TextEditingController editController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  FlutterSoundRecorder? _audioRecorder;
  FlutterSoundPlayer? _audioPlayer;
  bool _isRecording = false;
  String _recordDuration = '00:00';
  Timer? _timer;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  final Map<String, bool> _isPlaying = {};

  @override
  void initState() {
    super.initState();
    fetchMessages();
    _initRecorder();
    _initPlayer();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Izin mikrofon tidak diberikan');
    }

    _audioRecorder = FlutterSoundRecorder();
    await _audioRecorder!.openRecorder();
  }

  Future<void> _initPlayer() async {
    _audioPlayer = FlutterSoundPlayer();
    await _audioPlayer!.openPlayer();
    await _audioPlayer!
        .setSubscriptionDuration(const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioRecorder?.stopRecorder();
    _audioRecorder?.closeRecorder();
    _audioPlayer?.stopPlayer();
    _audioPlayer?.closePlayer();
    _timer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> sendMessageWithFile(String senderNoHp, String receiverNoHp,
      String content, File? mediaFile) async {
    var uri = Uri.parse("https://hayy.my.id/data/messages");
    var request = http.MultipartRequest('POST', uri)
      ..fields['sender_no_hp'] = senderNoHp
      ..fields['receiver_no_hp'] = receiverNoHp
      ..fields['content'] = content;

    if (mediaFile != null) {
      String mediaType = '';
      if (mediaFile.path.toLowerCase().endsWith('.jpg') ||
          mediaFile.path.toLowerCase().endsWith('.jpeg') ||
          mediaFile.path.toLowerCase().endsWith('.png')) {
        mediaType = 'image';
      } else if (mediaFile.path.toLowerCase().endsWith('.mp3') ||
          mediaFile.path.toLowerCase().endsWith('.wav')) {
        mediaType = 'voice_note';
      }

      request.fields['media_type'] = mediaType;
      request.files.add(await http.MultipartFile.fromPath(
          'media', mediaFile.path,
          contentType: mediaType == 'image'
              ? MediaType('image', 'jpeg')
              : MediaType('audio', 'mpeg')));
    }

    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      if (response.statusCode == 201) {
        print("Pesan berhasil dikirim");
      } else {
        print("Gagal mengirim pesan. Status: ${response.statusCode}");
        print("Response body: $responseBody");
      }
    } catch (e) {
      print("Error saat mengirim pesan: $e");
    }
  }

  Future<void> fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://hayy.my.id/data/messages/${widget.no_hp}/${widget.receiverNoHp}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success' &&
            jsonData.containsKey('messages')) {
          final List<dynamic> messagesList = jsonData['messages'];
          setState(() {
            messages = messagesList
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          });
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollToBottom();
          });
        }
      } else {
        print('Gagal mengambil pesan');
        _scaffoldKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Gagal mengambil pesan')));
      }
    } catch (e) {
      print('Error fetching messages: $e');
      _scaffoldKey.currentState
          ?.showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  Future<void> sendMessage(String content,
      {String? mediaType, String? mediaUrl}) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://hayy.my.id/data/messages'),
      );

      request.fields['sender_no_hp'] = widget.no_hp;
      request.fields['receiver_no_hp'] = widget.receiverNoHp;
      request.fields['content'] = content;

      if (mediaType != null) {
        request.fields['media_type'] = mediaType;
        if (mediaUrl != null) {
          request.files
              .add(await http.MultipartFile.fromPath('media', mediaUrl));
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        await fetchMessages();
        _scrollToBottom();
      } else {
        print('Gagal mengirim pesan');
        _scaffoldKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Gagal mengirim pesan')));
      }
    } catch (e) {
      print('Error sending message: $e');
      _scaffoldKey.currentState
          ?.showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  Future<void> sendMessageRequest({
    required String url,
    required String senderNoHp,
    required String receiverNoHp,
    required String content,
    File? mediaFile,
    String? mediaType,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse(url));

    request.fields['sender_no_hp'] = senderNoHp;
    request.fields['receiver_no_hp'] = receiverNoHp;
    request.fields['content'] = content;
    if (mediaType != null) {
      request.fields['media_type'] = mediaType;
    }

    if (mediaFile != null) {
      if (await mediaFile.exists()) {
        request.files.add(await http.MultipartFile.fromPath(
          'media',
          mediaFile.path,
          contentType: mediaType == 'image'
              ? MediaType('image', 'jpeg')
              : MediaType('audio', 'mpeg'),
        ));
      } else {
        print('File tidak ditemukan: ${mediaFile.path}');
      }
    }

    var response = await request.send();

    if (response.statusCode == 201) {
      print('Pesan berhasil dikirim');
    } else {
      print('Gagal mengirim pesan dengan status ${response.statusCode}');
      throw Exception('Gagal mengirim pesan');
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        sendMessage('', mediaType: 'image', mediaUrl: pickedFile.path);
      }
    } catch (e) {
      print('Error picking image: $e');
      _scaffoldKey.currentState
          ?.showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  void _startTimer() {
    int seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      seconds++;
      setState(() {
        _recordDuration =
            '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
      });
    });
  }

  Future<void> startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Izin mikrofon tidak diberikan');
      }

      Directory tempDir = Directory.systemTemp;
      String path =
          '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _audioRecorder!.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
      );
      setState(() {
        _isRecording = true;
      });
      _startTimer();
    } catch (e) {
      print('Error starting recording: $e');
      _scaffoldKey.currentState
          ?.showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  Future<void> stopRecording() async {
    try {
      String? path = await _audioRecorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _recordDuration = '00:00';
      });
      _timer?.cancel();
      sendMessage('', mediaType: 'voice_note', mediaUrl: path);
    } catch (e) {
      print('Error stopping recording: $e');
      _scaffoldKey.currentState
          ?.showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  Future<void> playVoiceNote(String url) async {
    try {
      if (_audioPlayer == null || !_audioPlayer!.isOpen()) {
        await _initPlayer();
      }

      if (_audioPlayer!.isPlaying) {
        await _audioPlayer!.stopPlayer();
        setState(() {
          _isPlaying.clear();
        });
        return;
      }

      if (url.startsWith('/')) {
        final response = await http.get(Uri.parse('https://hayy.my.id$url'));
        if (response.statusCode == 200) {
          Directory tempDir = Directory.systemTemp;
          String tempPath =
              '${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.aac';
          File tempFile = File(tempPath);
          await tempFile.writeAsBytes(response.bodyBytes);

          setState(() {
            _isPlaying[url] = true;
          });

          await _audioPlayer!.startPlayer(
              fromURI: tempPath,
              codec: Codec.aacADTS,
              whenFinished: () {
                setState(() {
                  _isPlaying[url] = false;
                });
                print('Selesai memutar audio');
                tempFile.delete();
              });
        } else {
          throw Exception('Gagal mengunduh file audio');
        }
      } else {
        setState(() {
          _isPlaying[url] = true;
        });

        await _audioPlayer!.startPlayer(
            fromURI: url,
            codec: Codec.aacADTS,
            whenFinished: () {
              setState(() {
                _isPlaying[url] = false;
              });
              print('Selesai memutar audio');
            });
      }
    } catch (e) {
      print('Error playing voice note: $e');
      _scaffoldKey.currentState?.showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan memutar audio: $e')));
    }
  }

  Future<void> makeCall(String callType) async {
    try {
      final response = await http.post(
        Uri.parse('https://hayy.my.id/data/calls'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'caller_no_hp': widget.no_hp,
          'receiver_no_hp': widget.receiverNoHp,
          'call_type': callType,
          'call_status': 'initiated',
          'timestamp': DateTime.now().toIso8601String()
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        if (callType == 'video') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoCallPage(
                callLogId: '',
                contactName: widget.contactName,
                phoneNumber: widget.receiverNoHp,
              ),
            ),
          );
        } else if (callType == 'audio') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CallVoicePage(
                contactName: widget.contactName,
                phoneNumber: widget.receiverNoHp,
                callLogId: '',
              ),
            ),
          );
        }

        await saveCallToDatabase(callType);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal melakukan panggilan: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error making call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  Future<void> saveCallToDatabase(String callType) async {
    try {
      final response = await http.post(
        Uri.parse('https://hayy.my.id/data/calls'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'caller_no_hp': widget.no_hp,
          'receiver_no_hp': widget.receiverNoHp,
          'call_type': callType,
          'call_status': 'completed',
          'timestamp': DateTime.now().toIso8601String()
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Gagal menyimpan panggilan ke database');
      }
    } catch (e) {
      print('Error saving call to database: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan riwayat panggilan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        backgroundColor: Colors.blue[700], // Changed to blue
        appBar: AppBar(
          backgroundColor: Colors.blue[700], // Changed to blue
          elevation: 0,
          leadingWidth: 70,
          leading: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const CircleAvatar(
                radius: 15,
                backgroundImage: AssetImage('assets/person.jpg'),
              ),
            ],
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.contactName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'online',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.videocam, color: Colors.white),
              onPressed: () => makeCall('video'),
            ),
            IconButton(
              icon: const Icon(Icons.call, color: Colors.white),
              onPressed: () => makeCall('audio'),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Colors.white, // Changed background to white
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final isSender = message['sender_no_hp'] == widget.no_hp;
                    return Align(
                      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(
                          bottom: 4,
                          left: isSender ? 80 : 0,
                          right: isSender ? 0 : 80,
                        ),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSender ? Colors.blue[100] : Colors.grey[100], // Changed bubble colors
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message['media_url'] != null) ...[
                              if (message['media_type'] == 'image') ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    'https://hayy.my.id${message['media_url']}',
                                    width: 200,
                                  ),
                                ),
                              ] else if (message['media_type'] == 'voice_note') ...[
                                GestureDetector(
                                  onTap: () => playVoiceNote(message['media_url']),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isPlaying[message['media_url']] ?? false
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.blue[700], // Changed to blue
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 150,
                                          height: 2,
                                          color: Colors.blue[700], // Changed to blue
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                            ],
                            Text(
                              message['content'] ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message['timestamp'],
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.emoji_emotions_outlined),
                              color: Colors.grey[600],
                              onPressed: () {},
                            ),
                            Expanded(
                              child: TextField(
                                controller: messageController,
                                decoration: const InputDecoration(
                                  hintText: 'Pesan',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                ),
                                onSubmitted: (text) {
                                  if (text.isNotEmpty) {
                                    sendMessage(text);
                                    messageController.clear();
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.attach_file),
                              color: Colors.grey[600],
                              onPressed: () => pickImage(ImageSource.gallery),
                            ),
                            IconButton(
                              icon: const Icon(Icons.camera_alt),
                              color: Colors.grey[600],
                              onPressed: () => pickImage(ImageSource.camera),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[700], // Changed to blue
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          messageController.text.isEmpty ? Icons.mic : Icons.send,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (messageController.text.isEmpty) {
                            _isRecording ? stopRecording() : startRecording();
                          } else {
                            sendMessage(messageController.text);
                            messageController.clear();
                          }
                        },
                      ),
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