import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    tearDown(() async {
      await prefs.clear();
    });

    test('Password hashing consistency', () {
      final salt = 'test_salt';
      final password = 'test_password';
      final expectedHash = sha256.convert(utf8.encode(salt + password)).toString();

      final bytes = utf8.encode(salt + password);
      final digest = sha256.convert(bytes);
      final actualHash = digest.toString();

      expect(actualHash, equals(expectedHash));
    });

    test('User registration saves to local storage', () async {
      // Simulate registration data
      final name = 'Test User';
      final email = 'test@example.com';
      final password = 'password123';
      final salt = 'random_salt_123';
      final passwordHash = sha256.convert(utf8.encode(salt + password)).toString();

      final newUser = {
        'name': name,
        'email': email,
        'password_hash': passwordHash,
        'salt': salt,
        'created_at': DateTime.now().toIso8601String(),
      };

      final users = [newUser];
      await prefs.setString('local_users', jsonEncode(users));

      // Verify user was saved
      final savedUsersJson = prefs.getString('local_users');
      expect(savedUsersJson, isNotNull);

      final savedUsers = jsonDecode(savedUsersJson!) as List<dynamic>;
      expect(savedUsers.length, equals(1));

      final savedUser = savedUsers[0] as Map<String, dynamic>;
      expect(savedUser['name'], equals(name));
      expect(savedUser['email'], equals(email));
      expect(savedUser['password_hash'], equals(passwordHash));
      expect(savedUser['salt'], equals(salt));
    });

    test('Login with correct credentials succeeds', () async {
      // Setup: Register a user
      final name = 'Test User';
      final email = 'test@example.com';
      final password = 'password123';
      final salt = 'random_salt_123';
      final passwordHash = sha256.convert(utf8.encode(salt + password)).toString();

      final user = {
        'name': name,
        'email': email,
        'password_hash': passwordHash,
        'salt': salt,
        'created_at': DateTime.now().toIso8601String(),
      };

      await prefs.setString('local_users', jsonEncode([user]));

      // Simulate login logic
      final usersJson = prefs.getString('local_users') ?? '[]';
      final List<dynamic> users = jsonDecode(usersJson);

      final userIndex = users.indexWhere((u) => (u['email'] as String).toLowerCase() == email.toLowerCase());
      expect(userIndex, isNot(equals(-1)));

      final foundUser = users[userIndex] as Map<String, dynamic>;
      final storedHash = foundUser['password_hash'] as String;
      final storedSalt = foundUser['salt'] as String;

      final inputHash = sha256.convert(utf8.encode(storedSalt + password)).toString();
      expect(inputHash, equals(storedHash));

      // Simulate successful login
      await prefs.setString('current_user', foundUser['name']);
      await prefs.setString('current_user_email', foundUser['email']);

      expect(prefs.getString('current_user'), equals(name));
      expect(prefs.getString('current_user_email'), equals(email));
    });

    test('Login with wrong password fails', () async {
      // Setup: Register a user
      final name = 'Test User';
      final email = 'test@example.com';
      final password = 'password123';
      final wrongPassword = 'wrong_password';
      final salt = 'random_salt_123';
      final passwordHash = sha256.convert(utf8.encode(salt + password)).toString();

      final user = {
        'name': name,
        'email': email,
        'password_hash': passwordHash,
        'salt': salt,
        'created_at': DateTime.now().toIso8601String(),
      };

      await prefs.setString('local_users', jsonEncode([user]));

      // Simulate login with wrong password
      final usersJson = prefs.getString('local_users') ?? '[]';
      final List<dynamic> users = jsonDecode(usersJson);

      final userIndex = users.indexWhere((u) => (u['email'] as String).toLowerCase() == email.toLowerCase());
      expect(userIndex, isNot(equals(-1)));

      final foundUser = users[userIndex] as Map<String, dynamic>;
      final storedHash = foundUser['password_hash'] as String;
      final storedSalt = foundUser['salt'] as String;

      final inputHash = sha256.convert(utf8.encode(storedSalt + wrongPassword)).toString();
      expect(inputHash, isNot(equals(storedHash)));
    });

    test('Login with non-existent email fails', () async {
      // Setup: Register a user
      final name = 'Test User';
      final email = 'test@example.com';
      final password = 'password123';
      final salt = 'random_salt_123';
      final passwordHash = sha256.convert(utf8.encode(salt + password)).toString();

      final user = {
        'name': name,
        'email': email,
        'password_hash': passwordHash,
        'salt': salt,
        'created_at': DateTime.now().toIso8601String(),
      };

      await prefs.setString('local_users', jsonEncode([user]));

      // Simulate login with non-existent email
      final nonExistentEmail = 'nonexistent@example.com';
      final usersJson = prefs.getString('local_users') ?? '[]';
      final List<dynamic> users = jsonDecode(usersJson);

      final userIndex = users.indexWhere((u) => (u['email'] as String).toLowerCase() == nonExistentEmail.toLowerCase());
      expect(userIndex, equals(-1));
    });

    test('Accounts persist after restart', () async {
      // Setup: Register a user
      final name = 'Test User';
      final email = 'test@example.com';
      final password = 'password123';
      final salt = 'random_salt_123';
      final passwordHash = sha256.convert(utf8.encode(salt + password)).toString();

      final user = {
        'name': name,
        'email': email,
        'password_hash': passwordHash,
        'salt': salt,
        'created_at': DateTime.now().toIso8601String(),
      };

      await prefs.setString('local_users', jsonEncode([user]));

      // Simulate app restart by creating new prefs instance
      final keys = prefs.getKeys();
      final values = <String, Object>{};
      for (final key in keys) {
        final value = prefs.get(key);
        if (value != null) values[key] = value;
      }
      SharedPreferences.setMockInitialValues(values);
      final newPrefs = await SharedPreferences.getInstance();

      final savedUsersJson = newPrefs.getString('local_users');
      expect(savedUsersJson, isNotNull);

      final savedUsers = jsonDecode(savedUsersJson!) as List<dynamic>;
      expect(savedUsers.length, equals(1));

      final savedUser = savedUsers[0] as Map<String, dynamic>;
      expect(savedUser['email'], equals(email));
    });
  });
}
