import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';

class ProfileEditPage extends StatefulWidget {
  final String no_hp;

  const ProfileEditPage({super.key, required this.no_hp});

  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late String userPhoneNumber;
  String userName = '';
  String userStatus = '';
  String userFoto = '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  String? _savedImagePath;

  @override
  void initState() {
    super.initState();
    userPhoneNumber = widget.no_hp;
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (userPhoneNumber.isEmpty) {
      _showErrorMessage('Nomor telepon pengguna tidak ditemukan');
      return;
    }

    try {
      final userData = await _getUserData();
      _updateUIWithUserData(userData);
    } catch (e) {
      _showErrorMessage('Gagal memuat profil: $e');
    }
  }

  Future<Map<String, dynamic>> _getUserData() async {
    final response = await http.get(
      Uri.parse('https://hayy.my.id/data/user/$userPhoneNumber'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal mengambil data pengguna');
    }
  }

  void _updateUIWithUserData(Map<String, dynamic> userData) {
    setState(() {
      userName = userData['nama'] ?? '';
      userStatus = userData['status'] ?? '';
      userFoto = userData['foto'] ?? '';
      _savedImagePath = userFoto;
      _nameController.text = userName;
      _statusController.text = userStatus;
    });
  }

  Future<void> _handleImageSelection() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        await _processSelectedImage(imageFile);
      }
    } catch (e) {
      _showErrorMessage('Gagal memilih gambar: $e');
    }
  }

  Future<void> _processSelectedImage(File imageFile) async {
    try {
      final String? localPath = await _saveImageLocally(imageFile);
      if (localPath != null) {
        setState(() {
          _image = imageFile;
          _savedImagePath = localPath;
        });
      }
    } catch (e) {
      _showErrorMessage('Gagal memproses gambar: $e');
    }
  }

  Future<String?> _saveImageLocally(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${userPhoneNumber}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final savedImage = await imageFile.copy('${directory.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      print('Error menyimpan gambar: $e');
      return null;
    }
  }

  Future<void> _submitProfileUpdate() async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('https://hayy.my.id/data/profile/$userPhoneNumber'),
      );

      request.fields['nama'] = _nameController.text;
      request.fields['status'] = _statusController.text;

      if (_image != null) {
        var imageStream = http.ByteStream(_image!.openRead());
        var length = await _image!.length();

        var multipartFile = http.MultipartFile(
          'foto',
          imageStream,
          length,
          filename: path.basename(_image!.path),
          contentType: MediaType('image', 'jpeg'),
        );

        request.files.add(multipartFile);
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Mengecek tipe konten dari response
      if (response.headers['content-type'] != null &&
          response.headers['content-type']!.contains('application/json')) {
        var responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          _showSuccessMessage('Profil berhasil diperbarui');
          Navigator.pop(context, true);
        } else {
          _showErrorMessage('Error: ${responseData['error']}');
        }
      } else {
        _showErrorMessage('Gagal memperbarui profil: ${response.body}');
      }
    } catch (e) {
      print('Gagal memperbarui profil: $e');
      _showErrorMessage('Gagal memperbarui profil: $e');
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profil', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _submitProfileUpdate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF075E54),
              padding: const EdgeInsets.only(bottom: 20),
              child: Center(
                child: Stack(
                  children: [
                    Hero(
                      tag: 'profile-photo',
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: _image != null
                            ? FileImage(_image!)
                            : _savedImagePath != null && _savedImagePath!.startsWith('http')
                                ? NetworkImage(_savedImagePath!) as ImageProvider
                                : const AssetImage('assets/default_profile.png'),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.teal[700],
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          onPressed: _handleImageSelection,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'Nama',
                      style: TextStyle(
                        color: Color(0xFF075E54),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'Nomor Telepon',
                      style: TextStyle(
                        color: Color(0xFF075E54),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      userPhoneNumber,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'Info',
                      style: TextStyle(
                        color: Color(0xFF075E54),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextField(
                    controller: _statusController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      border: UnderlineInputBorder(),
                      hintText: 'Tentang kamu',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}