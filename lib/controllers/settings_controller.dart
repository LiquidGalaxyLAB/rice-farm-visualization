import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController {
  static const String _hostKey = 'ssh_host';
  static const String _portKey = 'ssh_port';
  static const String _usernameKey = 'ssh_username';
  static const String _passwordKey = 'ssh_password';
  static const String _rigsNumKey = 'rigs_num';

  static const String defaultHost = '192.168.1.7';
  static const int defaultPort = 22;
  static const String defaultUsername = 'lg';
  static const String defaultPassword = '123';
  static const int defaultRigsNum = 3;

  String _lgHost = defaultHost;
  int _lgPort = defaultPort;
  String _lgUsername = defaultUsername;
  String _lgPassword = defaultPassword;
  int _lgRigsNum = defaultRigsNum;

  String get lgHost => _lgHost;
  int get lgPort => _lgPort;
  String get lgUsername => _lgUsername;
  String get lgPassword => _lgPassword;
  int get lgRigsNum => _lgRigsNum;

  Future<void> saveSettings({
    required String host,
    required int port,
    required String username,
    required String password,
    int rigsNum = defaultRigsNum,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_hostKey, host);
    await prefs.setInt(_portKey, port);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_passwordKey, password);
    await prefs.setInt(_rigsNumKey, rigsNum);

    _lgHost = host;
    _lgPort = port;
    _lgUsername = username;
    _lgPassword = password;
    _lgRigsNum = rigsNum;
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'host': prefs.getString(_hostKey) ?? defaultHost,
      'port': prefs.getInt(_portKey) ?? defaultPort,
      'username': prefs.getString(_usernameKey) ?? defaultUsername,
      'password': prefs.getString(_passwordKey) ?? defaultPassword,
    };
  }

  Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hostKey);
    await prefs.remove(_portKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_passwordKey);
  }
}
