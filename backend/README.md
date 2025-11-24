# Backend (PHP) for Puzzle Quest - Local XAMPP

This folder contains a minimal PHP REST API for local development using XAMPP (MySQL).

Files:
- `db.php` - mysqli connection helper (adjust credentials if needed)
- `register.php` - POST JSON {name, email, password} -> register user
- `login.php` - POST JSON {email, password} -> authenticate user
- `init.sql` - SQL to create database and `users` table

Setup
1. Copy this folder into your XAMPP `htdocs` directory or create a symlink. Example path on Windows:

   C:\xampp\htdocs\puzzle_quest_backend\

2. In phpMyAdmin (http://localhost/phpmyadmin) import `init.sql` or run from CLI:

   mysql -u root -p < backend/init.sql

3. Ensure `db.php` has the correct DB credentials (defaults: host=127.0.0.1, user=root, password='').

4. Start Apache & MySQL in XAMPP.

Testing endpoints
Use `curl` or Postman. If the backend is available at `http://localhost/puzzle_quest_backend/`:

Register (example):
```
curl -X POST http://localhost/puzzle_quest_backend/register.php \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","email":"alice@example.com","password":"secret123"}'
```

Login (example):
```
curl -X POST http://localhost/puzzle_quest_backend/login.php \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@example.com","password":"secret123"}'
```

Notes for Flutter
- If you run the Android emulator, use `http://10.0.2.2/puzzle_quest_backend/` as the host address.
- For iOS simulator, use `http://localhost/puzzle_quest_backend/`.
- For a physical device use your machine's LAN IP, e.g. `http://192.168.1.42/puzzle_quest_backend/` and ensure firewall allows connections.

Security
- This is a minimal demo for local development. Do not use this in production.
- Add prepared statements (already used), rate limiting, HTTPS, and proper session/token management for production.
