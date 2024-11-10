const express = require('express');
const mysql = require('mysql');
const cors = require('cors');
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Koneksi MySQL
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'chatpyy'
});

// Routes
app.get('/api/events', (req, res) => {
  const query = 'SELECT * FROM events ORDER BY date DESC';
  db.query(query, (err, results) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(results);
  });
});

app.get('/api/events/:id', (req, res) => {
  const query = 'SELECT * FROM events WHERE id = ?';
  db.query(query, [req.params.id], (err, results) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(results[0]);
  });
});

app.post('/api/events', (req, res) => {
  const { title, description, date } = req.body;
  const query = 'INSERT INTO events (title, description, date) VALUES (?, ?, ?)';
  
  db.query(query, [title, description, date], (err, result) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.status(201).json({ id: result.insertId, message: 'Event created successfully' });
  });
});

app.put('/api/events/:id', (req, res) => {
  const { title, description, date } = req.body;
  const query = 'UPDATE events SET title = ?, description = ?, date = ? WHERE id = ?';
  
  db.query(query, [title, description, date, req.params.id], (err) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json({ message: 'Event updated successfully' });
  });
});

app.delete('/api/events/:id', (req, res) => {
  const query = 'DELETE FROM events WHERE id = ?';
  db.query(query, [req.params.id], (err) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json({ message: 'Event deleted successfully' });
  });
});

// Routes untuk Notes/Journal
app.get('/api/notes', (req, res) => {
  const query = 'SELECT * FROM notes ORDER BY created_at DESC';
  db.query(query, (err, results) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(results);
  });
});

app.post('/api/notes', (req, res) => {
  const { title, content, image_url, is_private, shared_with } = req.body;
  const query = 'INSERT INTO notes (title, content, image_url, is_private, shared_with, created_at) VALUES (?, ?, ?, ?, ?, NOW())';
  
  db.query(query, [title, content, image_url, is_private, shared_with], (err, result) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.status(201).json({ id: result.insertId, message: 'Catatan berhasil dibuat' });
  });
});

app.put('/api/notes/:id', (req, res) => {
  const { title, content, image_url, is_private, shared_with } = req.body;
  const query = 'UPDATE notes SET title = ?, content = ?, image_url = ?, is_private = ?, shared_with = ? WHERE id = ?';
  
  db.query(query, [title, content, image_url, is_private, shared_with, req.params.id], (err) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json({ message: 'Catatan berhasil diperbarui' });
  });
});

app.delete('/api/notes/:id', (req, res) => {
  const query = 'DELETE FROM notes WHERE id = ?';
  db.query(query, [req.params.id], (err) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json({ message: 'Catatan berhasil dihapus' });
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server berjalan di port ${PORT}`);
}); 