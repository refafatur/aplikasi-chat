import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'video_call.dart';
import 'call_voice.dart';
import 'incoming_call.dart';

class CallPage extends StatefulWidget {
  final String no_hp;
  const CallPage({super.key, required this.no_hp});

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> with SingleTickerProviderStateMixin {
  List<dynamic> callLogs = [];
  List<dynamic> users = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchCallLogs();
    fetchUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('https://hayy.my.id/data/user'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            users = json.decode(response.body);
          });
        }
      } else {
        print('Failed to load users');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat pengguna')),
        );
      }
    } catch (e) {
      print('Error fetching users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan saat memuat pengguna')),
      );
    }
  }

  Future<void> fetchCallLogs() async {
    try {
      final response = await http.get(Uri.parse('https://hayy.my.id/data/calls'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            callLogs = json.decode(response.body);
          });
        }
      } else {
        print('Failed to load call logs');
      }
    } catch (e) {
      print('Error fetching call logs: $e');
    }
  }

  Future<void> makeCall(String receiverNoHp, String callType) async {
    try {
      final response = await http.post(
        Uri.parse('https://hayy.my.id/data/calls'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'caller_no_hp': widget.no_hp,
          'receiver_no_hp': receiverNoHp,
          'call_type': callType,
          'call_status': 'initiated'
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        fetchCallLogs();
        
        final callLogId = json.decode(response.body)['callId'];

        if (callType == 'video') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoCallPage(
                contactName: widget.no_hp,
                phoneNumber: receiverNoHp,
                callLogId: callLogId,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CallVoicePage(
                contactName: widget.no_hp,
                phoneNumber: receiverNoHp,
                callLogId: callLogId,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan')),
      );
    }
  }

  void _onIncomingCall(String callerName, String callerNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncomingCallPage(
          callerName: callerName,
          callerNumber: callerNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              pinned: true,
              floating: true,
              title: const Text('Panggilan', 
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold
                )
              ),
              backgroundColor: Colors.blue,
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
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'SEMUA'),
                  Tab(text: 'TIDAK TERJAWAB'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCallList(callLogs),
            _buildCallList(callLogs.where((log) => log['call_status'] == 'missed').toList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add_call, color: Colors.white),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Pilih Kontak'),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      if (user['no_hp'] != null && user['no_hp'] != widget.no_hp) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage('https://picsum.photos/200?random=$index'),
                          ),
                          title: Text(user['nama'] ?? 'Pengguna'),
                          subtitle: Text(user['no_hp'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.videocam, color: Colors.blue),
                                onPressed: () {
                                  Navigator.pop(context);
                                  makeCall(user['no_hp'], 'video');
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.call, color: Colors.blue),
                                onPressed: () {
                                  Navigator.pop(context);
                                  makeCall(user['no_hp'], 'audio');
                                },
                              ),
                            ],
                          ),
                        );
                      }
                      return Container();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCallList(List<dynamic> logs) {
    if (logs.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada riwayat panggilan',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final bool isMissed = log['call_status'] == 'missed';
        
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage('https://picsum.photos/200?random=$index'),
            radius: 25,
          ),
          title: Text(
            log['caller_no_hp'] == widget.no_hp ? log['receiver_no_hp'] : log['caller_no_hp'],
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isMissed ? Colors.red : Colors.black,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(
                log['caller_no_hp'] == widget.no_hp ? Icons.call_made : Icons.call_received,
                size: 16,
                color: isMissed ? Colors.red : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                '${log['call_type'] == 'video' ? 'Video call' : 'Voice call'} • ${log['call_status']}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              log['call_type'] == 'video' ? Icons.videocam : Icons.call,
              color: Colors.blue,
            ),
            onPressed: () => makeCall(
              log['caller_no_hp'] == widget.no_hp ? log['receiver_no_hp'] : log['caller_no_hp'],
              log['call_type'],
            ),
          ),
        );
      },
    );
  }
}