import 'package:flutter/material.dart';
import 'chat_detail.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.no_hp});
  final String no_hp;

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> chatList = [];
  List<Map<String, dynamic>> userList = [];

  @override
  void initState() {
    super.initState();
    getCurrentUserNoHp();
  }

  Future<void> getCurrentUserNoHp() async {
    fetchChatList();
    fetchUserList(); 
  }

  Future<void> fetchChatList() async {
    try {
      final response = await http.get(
        Uri.parse('https://hayy.my.id/data/user'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          chatList = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        print('Gagal mengambil daftar chat: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saat mengambil daftar chat: $e');
    }
  }

  Future<void> fetchUserList() async {
    try {
      final response = await http.get(
        Uri.parse('https://hayy.my.id/data/user'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          userList = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        print('Gagal mengambil daftar pengguna: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saat mengambil daftar pengguna: $e');
    }
  }

  Future<void> sendMessage(String noHp, String receiverNoHp, String content) async {
    try {
      final response = await http.post(
        Uri.parse('https://hayy.my.id/data/messages'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'sender_no_hp': noHp,
          'receiver_no_hp': receiverNoHp,
          'content': content,
        }),
      );

      if (response.statusCode == 201) {
        print('Pesan terkirim');
        await fetchChatList();
      } else {
        print('Gagal mengirim pesan: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saat mengirim pesan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'WhatsApp',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold
          )
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              // Handle menu selection
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'new_group',
                child: Text('Grup baru'),
              ),
              const PopupMenuItem(
                value: 'new_broadcast',
                child: Text('Siaran baru'),
              ),
              const PopupMenuItem(
                value: 'linked_devices',
                child: Text('Perangkat tertaut'),
              ),
              const PopupMenuItem(
                value: 'starred_messages',
                child: Text('Pesan berbintang'),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Setelan'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.separated(
          itemCount: userList.length,
          separatorBuilder: (context, index) => const Divider(height: 0.5),
          itemBuilder: (context, index) {
            final user = userList[index];
            return Container(
              color: Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue[100],
                  backgroundImage: const AssetImage('assets/person.jpg'),
                ),
                title: Text(
                  user['nama'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue
                  ),
                ),
                subtitle: Row(
                  children: [
                    Icon(Icons.done_all, size: 16, color: Colors.blue[300]),
                    const SizedBox(width: 4),
                    Text(
                      'Pesan terakhir',
                      style: TextStyle(
                        color: Colors.blue[200],
                        fontSize: 14
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  '12:00',
                  style: TextStyle(
                    color: Colors.blue[300],
                    fontSize: 12
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailPage(
                        callLogId: '',
                        contactName: user['nama'] ?? 'Unknown',
                        no_hp: widget.no_hp,
                        receiverNoHp: user['no_hp'] ?? '',
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue,
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }
}