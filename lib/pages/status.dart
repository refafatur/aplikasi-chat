import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class StatusPage extends StatefulWidget {
  final String no_hp;
  const StatusPage({super.key, required this.no_hp});

  @override
  _StatusPageState createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  final List<Map<String, dynamic>> statusList = [];
  final TextEditingController _statusController = TextEditingController();
  Timer? _refreshTimer;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  int _currentMyStatusIndex = 0;

  String _formatTime(String dateTimeStr) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeStr);
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateTimeStr;
    }
  }

  void _viewStatusDetail(String noHp, String content, String? image, String createdAt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusDetailPage(
          noHp: noHp,
          content: content,
          image: image,
          createdAt: createdAt,
          onTimeout: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchStatuses(); // Panggil saat inisialisasi
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchStatuses(); // Refresh data setiap 30 detik
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _addStatus(); 
    }
  }

  Future<void> _fetchStatuses() async {
    try {
      final response = await http.get(
        Uri.parse('https://hayy.my.id/data/statuses'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> statuses = data['statuses'];
          setState(() {
            statusList.clear();
            statusList.addAll(statuses.map((status) => {
              'id': status['id'],
              'no_hp': status['no_hp'],
              'content': status['content'],
              'created_at': status['created_at'],
              'image': status['image'],
            }).toList());
          });
        } else {
          print('Status tidak berhasil: ${data['status']}');
        }
      } else {
        print('Failed to fetch statuses. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching statuses: $e');
    }
  }

  Future<void> _addStatus() async {
    final content = _statusController.text;
    if (content.isNotEmpty || _image != null) {
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://hayy.my.id/data/statuses'),
        );

        request.fields['no_hp'] = widget.no_hp;
        request.fields['content'] = content;

        if (_image != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              _image!.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          _statusController.clear();
          setState(() {
            _image = null;
          });
          _fetchStatuses(); // Refresh data setelah menambah status
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Status berhasil dibuat')),
          );
        } else {
          print('Gagal menambah status: ${response.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuat status')),
          );
        }
      } catch (e) {
        print('Error menambah status: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan saat membuat status')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi status atau tambahkan gambar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text('Status', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            mini: true,
            backgroundColor: Colors.blue[100],
            child: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _addStatusDialog(context),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            backgroundColor: Colors.blue,
            child: const Icon(Icons.camera_alt, color: Colors.white),
            onPressed: () => pickImage(ImageSource.camera),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          children: [
            // Status Saya
            if (statusList.isEmpty)
              ListTile(
                leading: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, size: 35, color: Colors.white),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        height: 20,
                        width: 20,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 15),
                      ),
                    ),
                  ],
                ),
                title: const Text('Status saya'),
                subtitle: const Text('Ketuk untuk menambahkan pembaruan status'),
                onTap: () => _addStatusDialog(context),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text('Status saya', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ),
                    InkWell(
                      onTap: () {
                        _viewStatusDetail(
                          statusList[_currentMyStatusIndex]['no_hp'],
                          statusList[_currentMyStatusIndex]['content'],
                          statusList[_currentMyStatusIndex]['image'],
                          statusList[_currentMyStatusIndex]['created_at'],
                        );
                      },
                      child: ListTile(
                        leading: Stack(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blue, width: 2),
                              ),
                              child: statusList[_currentMyStatusIndex]['image'] != null
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(statusList[_currentMyStatusIndex]['image']),
                                  )
                                : const CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    child: Icon(Icons.person, size: 35, color: Colors.white),
                                  ),
                            ),
                            if (statusList.length > 1)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_currentMyStatusIndex + 1}/${statusList.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(widget.no_hp),
                        subtitle: Text(_formatTime(statusList[_currentMyStatusIndex]['created_at'])),
                      ),
                    ),
                  ],
                ),
              ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('PEMBARUAN TERBARU',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: statusList.length,
              itemBuilder: (context, index) {
                final status = statusList[index];
                return ListTile(
                  leading: Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: status['image'] != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(status['image']),
                        )
                      : const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.person, size: 35, color: Colors.white),
                        ),
                  ),
                  title: Text(status['no_hp'] ?? ''),
                  subtitle: Text(_formatTime(status['created_at'] ?? '')),
                  onTap: () => _viewStatusDetail(
                    status['no_hp'] ?? '',
                    status['content'] ?? '',
                    status['image'],
                    status['created_at'] ?? '',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Status', style: TextStyle(color: Colors.blue)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _statusController,
                decoration: InputDecoration(
                  hintText: 'Masukkan status baru',
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.photo_camera, color: Colors.blue),
                    onPressed: () {
                      Navigator.pop(context);
                      pickImage(ImageSource.camera);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.photo_library, color: Colors.blue),
                    onPressed: () {
                      Navigator.pop(context);
                      pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addStatus();
              },
              child: Text('Tambah', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }
}

class StatusDetailPage extends StatefulWidget {
  final String noHp;
  final String content;
  final String? image;
  final String createdAt;
  final VoidCallback onTimeout;

  const StatusDetailPage({
    super.key,
    required this.noHp,
    required this.content,
    this.image,
    required this.createdAt,
    required this.onTimeout,
  });

  @override
  State<StatusDetailPage> createState() => _StatusDetailPageState();
}

class _StatusDetailPageState extends State<StatusDetailPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      widget.onTimeout();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(String dateTimeStr) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeStr);
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.noHp,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              _formatTime(widget.createdAt),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Center(
        child: widget.image != null
          ? Image.network(widget.image!)
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.content,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
      ),
    );
  }
}