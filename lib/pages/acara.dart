import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EventsPage extends StatefulWidget {
  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};
  String _eventTitle = '';
  String _eventDescription = '';
  DateTime _eventDateTime = DateTime.now();

  // final String baseUrl = 'http://10.0.2.2:3000/api'; // Untuk Android Emulator
  final String baseUrl = 'http://localhost:3000/api'; // Untuk iOS Simulator

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  // CREATE - Membuat event baru
  Future<void> _saveEvent() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/events'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': _eventTitle,
          'description': _eventDescription,
          'date': _selectedDay?.toIso8601String() ?? _focusedDay.toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        await _loadEvents();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Acara berhasil disimpan'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Gagal menyimpan acara: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat menyimpan acara'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // READ - Mengambil semua event
  Future<void> _loadEvents() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/events'));
      if (response.statusCode == 200) {
        final List<dynamic> eventsJson = json.decode(response.body);
        setState(() {
          _events.clear();
          for (var eventJson in eventsJson) {
            final DateTime date = DateTime.parse(eventJson['date']);
            final event = Event(
              eventJson['title'],
              date,
              id: eventJson['id'],
              description: eventJson['description'],
            );
            
            // Normalisasi tanggal untuk key
            final DateTime dateKey = DateTime(date.year, date.month, date.day);
            if (_events[dateKey] == null) {
              _events[dateKey] = [];
            }
            _events[dateKey]!.add(event);
          }
        });
        
        // Memaksa refresh tampilan setelah data dimuat
        if (_selectedDay != null) {
          setState(() {});
        }
      }
    } catch (e) {
      print('Error loading events: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // READ - Mengambil detail event berdasarkan ID
  Future<Event?> _getEvent(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/events/$id'));
      if (response.statusCode == 200) {
        final eventJson = json.decode(response.body);
        return Event(
          eventJson['title'],
          DateTime.parse(eventJson['date']),
          id: eventJson['id'],
          description: eventJson['description'],
        );
      }
      return null;
    } catch (e) {
      print('Error getting event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mendapatkan detail acara'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }
  }

  // UPDATE - Memperbarui event yang sudah ada
  Future<void> _updateEvent(int eventId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': _eventTitle,
          'description': _eventDescription,
          'date': _selectedDay?.toIso8601String() ?? _focusedDay.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        await _loadEvents();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Acara berhasil diperbarui'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Gagal memperbarui acara');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat memperbarui acara'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // DELETE - Menghapus event
  Future<void> _deleteEvent(int eventId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/events/$eventId'),
      );

      if (response.statusCode == 200) {
        await _loadEvents();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Acara berhasil dihapus'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Gagal menghapus acara');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat menghapus acara'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kalender & Acara'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[100]!, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Card(
              margin: EdgeInsets.all(8.0),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  // Memuat ulang events setiap kali tanggal dipilih
                  _loadEvents();
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                eventLoader: (day) {
                  // Normalisasi tanggal untuk mencari events
                  final normalizedDay = DateTime(day.year, day.month, day.day);
                  return _events[normalizedDay] ?? [];
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                margin: EdgeInsets.all(8.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListView(
                  padding: EdgeInsets.all(8.0),
                  children: [
                    ..._getEventsForDay(_selectedDay ?? _focusedDay)
                        .map((event) => Card(
                              elevation: 2,
                              margin: EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              child: ListTile(
                                leading: Icon(Icons.event, color: Colors.blue),
                                title: Text(
                                  event.title,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('HH:mm').format(event.dateTime),
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    if (event.description != null)
                                      Text(
                                        event.description!,
                                        style: TextStyle(color: Colors.grey[800]),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showEditEventDialog(event),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () =>
                                          _showDeleteConfirmation(event.id),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.share, color: Colors.green),
                                      onPressed: () {
                                        // Implementasi berbagi acara
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddEventDialog();
        },
        icon: Icon(Icons.add),
        label: Text('Tambah Acara'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  List<Event> _getEventsForDay(DateTime day) {
    // Normalisasi tanggal untuk mencari events
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  // Dialog untuk menambah event baru
  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          'Tambah Acara Baru',
          style: TextStyle(color: Colors.blue),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Judul Acara',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              onChanged: (value) {
                _eventTitle = value;
              },
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              onChanged: (value) {
                _eventDescription = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Batal', style: TextStyle(color: Colors.grey)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text('Simpan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: _saveEvent,
          ),
        ],
      ),
    );
  }

  // Dialog konfirmasi hapus event
  void _showDeleteConfirmation(int eventId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text('Hapus Acara'),
        content: Text('Apakah Anda yakin ingin menghapus acara ini?'),
        actions: [
          TextButton(
            child: Text('Batal', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text('Hapus'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteEvent(eventId);
            },
          ),
        ],
      ),
    );
  }

  // Dialog untuk mengedit event
  void _showEditEventDialog(Event event) {
    _eventTitle = event.title;
    _eventDescription = event.description ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          'Edit Acara',
          style: TextStyle(color: Colors.blue),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Judul Acara',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              controller: TextEditingController(text: _eventTitle),
              onChanged: (value) => _eventTitle = value,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              controller: TextEditingController(text: _eventDescription),
              maxLines: 3,
              onChanged: (value) => _eventDescription = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Batal', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text('Simpan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () => _updateEvent(event.id),
          ),
        ],
      ),
    );
  }
}

class Event {
  final String title;
  final DateTime dateTime;
  final String? description;
  final int id;

  Event(this.title, this.dateTime, {this.description, required this.id});
}
