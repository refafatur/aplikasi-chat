import 'package:flutter/material.dart';
import '../pages/chat.dart';
import '../pages/status.dart';
import '../pages/community.dart';
import '../pages/call.dart';
import '../pages/setting.dart';
import '../pages/acara.dart';
import '../pages/notes.dart';

class DashboardScreen extends StatefulWidget {
  final String phoneNumber;
  const DashboardScreen({super.key, required this.phoneNumber});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  
  // Tambahkan variabel untuk menyimpan jumlah notifikasi
  final List<int> _notificationCounts = [2, 1, 0, 3, 0, 0, 0]; // Contoh jumlah notifikasi

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      ChatPage(no_hp: widget.phoneNumber),
      StatusPage(no_hp: widget.phoneNumber),
      CommunityPage(currentUserNama: widget.phoneNumber, community_id: ''),
      CallPage(no_hp: widget.phoneNumber),
      EventsPage(),
      NotesPage(),
      SettingPage(no_hp: widget.phoneNumber),
    ];
  }   

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Reset notifikasi saat tab dipilih
      _notificationCounts[index] = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            _buildBottomNavItem(Icons.chat_bubble, 'Obrolan', 0),
            _buildBottomNavItem(Icons.camera_alt, 'Status', 1),
            _buildBottomNavItem(Icons.group, 'Komunitas', 2),
            _buildBottomNavItem(Icons.call, 'Panggilan', 3),
            _buildBottomNavItem(Icons.calendar_today, 'Acara', 4),
            _buildBottomNavItem(Icons.note, 'Catatan', 5),
            _buildBottomNavItem(Icons.settings, 'Pengaturan', 6),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Stack(
        children: [
          Icon(icon),
          if (_notificationCounts[index] > 0)
            Positioned(
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(
                  minWidth: 12,
                  minHeight: 12,
                ),
                child: Text(
                  '${_notificationCounts[index]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      label: label,
      backgroundColor: Colors.white,
    );
  }
}
