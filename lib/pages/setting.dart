import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile.dart';

class SettingPage extends StatefulWidget {
  final String no_hp;

  const SettingPage({super.key, required this.no_hp});

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String userName = '';
  String userPhotoUrl = 'https://picsum.photos/200';
  String userPhoneNumber = '';
  String userStatus = '';

  @override
  void initState() {
    super.initState();
    _loadUserPhoneNumber();
  }

  Future<void> _loadUserPhoneNumber() async {
    setState(() {
      userPhoneNumber = widget.no_hp;
    });
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (userPhoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor telepon pengguna tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://hayy.my.id/data/user/$userPhoneNumber'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          userName = userData['nama'] ?? 'Nama Pengguna';
          userPhotoUrl = userData['foto'] ?? 'https://picsum.photos/200';
          userStatus = userData['status'] ?? 'Status tidak tersedia';
        });
      } else {
        throw Exception('Gagal mengambil data pengguna');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat mengambil data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        title: const Text('Setelan', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: ListView(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(no_hp: userPhoneNumber)));
            },
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(userPhotoUrl),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(userStatus, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.qr_code, color: Color(0xFF075E54), size: 28),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.key, color: Color(0xFF075E54)),
                  title: const Text('Akun'),
                  subtitle: const Text('Privasi, keamanan, ganti nomor'),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const Icon(Icons.chat, color: Color(0xFF075E54)),
                  title: const Text('Chat'),
                  subtitle: const Text('Tema, wallpaper, riwayat chat'),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const Icon(Icons.notifications, color: Color(0xFF075E54)),
                  title: const Text('Notifikasi'),
                  subtitle: const Text('Pesan, grup & nada dering panggilan'),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const Icon(Icons.data_usage, color: Color(0xFF075E54)),
                  title: const Text('Penyimpanan dan data'),
                  subtitle: const Text('Penggunaan jaringan, unduhan otomatis'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline, color: Color(0xFF075E54)),
                  title: const Text('Bantuan'),
                  subtitle: const Text('Pusat bantuan, hubungi kami, kebijakan privasi'),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const Icon(Icons.group, color: Color(0xFF075E54)),
                  title: const Text('Undang teman'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: const [
                Text('ChatPyy', style: TextStyle(color: Colors.grey, fontSize: 16)),
                SizedBox(height: 4),
                Text('Versi 1.0.0', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}