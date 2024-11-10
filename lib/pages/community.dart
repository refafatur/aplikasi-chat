import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CommunityPage extends StatefulWidget {
  final String currentUserNama;
  final String community_id;
  const CommunityPage({super.key, required this.currentUserNama, required this.community_id});

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  List<dynamic> communities = [];
  List<dynamic> communityMessages = [];
  TextEditingController messageController = TextEditingController();
  TextEditingController memberController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCommunities();
  }

  Future<void> fetchCommunities() async {
    try {
      final response = await http.get(
        Uri.parse('https://hayy.my.id/data/${widget.currentUserNama}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          communities = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching communities: $e');
    }
  }

  Future<void> fetchCommunityMessages() async {
    try {
      final response = await http.get(
        Uri.parse('https://hayy.my.id/data/${widget.community_id}/messages'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map) {
          setState(() {
            communityMessages = [data];
          });
        } else if (data is List) {
          setState(() {
            communityMessages = data;
          });
        }
      }
    } catch (e) {
      print('Error fetching community messages: $e');
    }
  }

  Future<void> addMember(String communityId) async {
    if (memberController.text.isEmpty || isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://hayy.my.id/data/addMember'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'community_id': communityId,
          'member_nama': memberController.text,
        }),
      );

      if (response.statusCode == 201) {
        memberController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anggota berhasil ditambahkan')),
        );
      }
    } catch (e) {
      print('Error adding member: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menambahkan anggota')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> sendMessage(String communityId) async {
    if (messageController.text.isEmpty || isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://hayy.my.id/data/$communityId/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sender': widget.currentUserNama,
          'message': messageController.text,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        messageController.clear();
        await fetchCommunityMessages();
      }
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim pesan')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _createNewCommunity() {
    showDialog(
      context: context,
      builder: (context) {
        String name = '';
        String description = '';

        return AlertDialog(
          title: const Text('Buat Komunitas Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Nama Komunitas'),
                onChanged: (value) => name = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                onChanged: (value) => description = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final response = await http.post(
                    Uri.parse('https://hayy.my.id/data/create'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({
                      'name': name,
                      'description': description,
                      'admin_nama': widget.currentUserNama,
                    }),
                  );

                  if (response.statusCode == 201) {
                    Navigator.pop(context);
                    fetchCommunities();
                  }
                } catch (e) {
                  print('Error creating community: $e');
                }
              },
              child: const Text('Buat'),
            ),
          ],
        );
      },
    );
  }

  void _showCommunityDetail(Map<String, dynamic> community) {
    fetchCommunityMessages();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(community['name'].toString()[0], style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(community['name'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(community['description'].toString(),
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (community['role'] == 'admin')
                    IconButton(
                      icon: const Icon(Icons.person_add, color: Colors.blue),
                      onPressed: isLoading ? null : () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Tambah Anggota'),
                            content: TextField(
                              controller: memberController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Anggota',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: isLoading ? null : () {
                                  addMember(community['id'].toString());
                                  Navigator.pop(context);
                                },
                                child: const Text('Tambah'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: communityMessages.length,
                  itemBuilder: (context, index) {
                    final message = communityMessages[index];
                    return ListTile(
                      title: Text(message['sender'].toString()),
                      subtitle: Text(message['message'].toString()),
                      trailing: Text(message['timestamp'].toString()),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        decoration: const InputDecoration(
                          hintText: 'Ketik pesan...',
                        ),
                        enabled: !isLoading,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: isLoading ? null : () => sendMessage(community['id'].toString()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Komunitas',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          Container(
            color: Colors.blue,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.people, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Komunitas Baru',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(
                          'Buat komunitas pribadi atau bergabung dengan yang sudah ada',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Komunitas Anda',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(community['name'].toString()[0], 
                      style: const TextStyle(color: Colors.white)),
                ),
                title: Text(community['name'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(community['description'].toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: community['role'] == 'admin'
                    ? const Icon(Icons.admin_panel_settings, color: Colors.blue)
                    : null,
                onTap: () => _showCommunityDetail(community),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewCommunity,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}