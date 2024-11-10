import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Note {
  final int? id;
  final String title;
  final String content;
  final String? imageUrl;
  final bool isPrivate;
  final String? sharedWith;
  final DateTime createdAt;

  Note({
    this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.isPrivate,
    this.sharedWith,
    required this.createdAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      imageUrl: json['image_url'],
      isPrivate: json['is_private'] == 1,
      sharedWith: json['shared_with'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Note> notes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/notes'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          notes = data.map((json) => Note.fromJson(json)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3000/api/notes/$id'),
      );
      if (response.statusCode == 200) {
        setState(() {
          notes.removeWhere((note) => note.id == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Catatan berhasil dihapus')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus catatan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catatan'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(note.title),
                    subtitle: Text(
                      note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => deleteNote(note.id!),
                    ),
                    onTap: () {
                      // Navigasi ke halaman edit catatan
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteFormPage(note: note),
                        ),
                      ).then((_) => fetchNotes());
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteFormPage(),
            ),
          ).then((_) => fetchNotes());
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class NoteFormPage extends StatefulWidget {
  final Note? note;

  NoteFormPage({this.note});

  @override
  _NoteFormPageState createState() => _NoteFormPageState();
}

class _NoteFormPageState extends State<NoteFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isPrivate = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _isPrivate = widget.note?.isPrivate ?? false;
  }

  Future<void> saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'title': _titleController.text,
      'content': _contentController.text,
      'is_private': _isPrivate,
      'image_url': null,
      'shared_with': null,
    };

    try {
      final response = widget.note == null
          ? await http.post(
              Uri.parse('http://localhost:3000/api/notes'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(data),
            )
          : await http.put(
              Uri.parse('http://localhost:3000/api/notes/${widget.note!.id}'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(data),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Catatan berhasil disimpan')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan catatan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Tambah Catatan' : 'Edit Catatan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Judul'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Judul tidak boleh kosong';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(labelText: 'Isi Catatan'),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Isi catatan tidak boleh kosong';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Catatan Pribadi'),
              value: _isPrivate,
              onChanged: (value) {
                setState(() => _isPrivate = value);
              },
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: saveNote,
              child: Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
