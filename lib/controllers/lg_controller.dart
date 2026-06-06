import 'package:flutter/foundation.dart';
import 'ssh_controller.dart';
import 'settings_controller.dart';

class LGController {
  LGController({
    required SSHController sshController,
    required SettingsController settingsController,
  }) : _sshController = sshController,
       _settingsController = settingsController,
       screenAmount = settingsController.lgRigsNum;

  final SSHController _sshController;
  final SettingsController _settingsController;

  int screenAmount;

  bool get isConnected => _sshController.isConnected;
  String? get lastError => _sshController.lastError;

  Future<bool> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    final success = await _sshController.connect(
      host: host,
      port: port,
      username: username,
      password: password,
    );

    if (success) {
      await _settingsController.saveSettings(
        host: host,
        port: port,
        username: username,
        password: password,
        rigsNum: screenAmount,
      );
      await enableSlaveRefresh();
    }

    return success;
  }

  Future<void> disconnect() async {
    _sshController.disconnect();
  }

  /// Reconnects using saved settings
  Future<bool> reconnect() async {
    try {
      _sshController.disconnect();
      await Future.delayed(const Duration(milliseconds: 500));
      return await connect(
        host: _settingsController.lgHost,
        port: _settingsController.lgPort,
        username: _settingsController.lgUsername,
        password: _settingsController.lgPassword,
      );
    } catch (e) {
      debugPrint('Reconnect failed: $e');
      return false;
    }
  }

  /// Executes a command with auto-reconnect on failure
  Future<String> safeExecute(String command) async {
    try {
      return await executeCommand(command);
    } catch (e) {
      debugPrint('Command failed, reconnecting: $e');
      final success = await reconnect();
      if (success) {
        return await executeCommand(command);
      }
      rethrow;
    }
  }

  /// Sends query with auto-reconnect on failure
  Future<void> safeQuery(String content) async {
    try {
      await query(content);
    } catch (e) {
      debugPrint('Query failed, reconnecting: $e');
      final success = await reconnect();
      if (success) {
        await query(content);
      }
    }
  }

  Future<String> executeCommand(String command) async {
    if (!isConnected) {
      throw Exception('Not connected to LG');
    }
    return _sshController.executeCommand(command);
  }

  Future<Map<String, dynamic>> loadSettings() async {
    return _settingsController.loadSettings();
  }

  Future<void> saveSettings({
    required String host,
    required int port,
    required String username,
    required String password,
    required int rigsNum,
  }) async {
    screenAmount = rigsNum;
    await _settingsController.saveSettings(
      host: host,
      port: port,
      username: username,
      password: password,
      rigsNum: rigsNum,
    );
  }

  int getLogoScreen() {
    if (screenAmount <= 1) return 1;
    return (screenAmount / 2).floor() + 2;
  }

  int get firstScreen => screenAmount <= 1 ? 1 : (screenAmount / 2).floor() + 2;

  int get lastScreen => screenAmount <= 1 ? 1 : (screenAmount / 2).floor();

  Future<void> sendKMLToSlave(int screen, String content) async {
    if (!isConnected) {
      throw Exception('Not connected to LG');
    }

    await _sshController.uploadString(
      content,
      '/var/www/html/kml/slave_$screen.kml',
    );
  }

  Future<void> query(String content) async {
    if (!isConnected) {
      throw Exception('Not connected to LG');
    }

    await executeCommand('echo "$content" > /tmp/query.txt');
  }

  Future<void> forceRefresh() async {
    if (!isConnected) return;

    await executeCommand('touch /var/www/html/kmls.txt');
    await query('search=http://${_settingsController.lgHost}:81/kmls.txt');
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> sendKmlToMaster(
    String kmlContent, {
    String filename = 'rice_viz.kml',
  }) async {
    if (!isConnected) {
      await reconnect();
    }

    await _sshController.uploadString(kmlContent, '/var/www/html/$filename');

    await Future.delayed(const Duration(milliseconds: 500));

    await safeExecute(
      "echo '\nhttp://${_settingsController.lgHost}:81/$filename' > /var/www/html/kmls.txt",
    );
  }

  Future<void> enableSlaveRefresh() async {
    if (!isConnected) return;

    final String password = _settingsController.lgPassword;

    for (int i = 2; i <= screenAmount; i++) {
      String search = '<href>##LG_PHPIFACE##kml\\\\/slave_$i.kml<\\\\/href>';
      String replace =
          '<href>##LG_PHPIFACE##kml\\\\/slave_$i.kml<\\\\/href>'
          '<refreshMode>onInterval<\\\\/refreshMode>'
          '<refreshInterval>2<\\\\/refreshInterval>';

      try {
        await executeCommand(
          'sshpass -p $password ssh -t lg$i '
          '\'echo $password | sudo -S sed -i "s/$search/$replace/" '
          '~/earth/kml/slave/myplaces.kml\'',
        );
      } catch (e) {
        debugPrint('Failed to enable refresh on slave $i: $e');
      }
    }
  }

  Future<void> disableSlaveRefresh() async {
    if (!isConnected) return;

    final String password = _settingsController.lgPassword;

    for (int i = 2; i <= screenAmount; i++) {
      String search =
          '<href>##LG_PHPIFACE##kml\\\\/slave_$i.kml<\\\\/href>'
          '<refreshMode>onInterval<\\\\/refreshMode>'
          '<refreshInterval>2<\\\\/refreshInterval>';
      String replace = '<href>##LG_PHPIFACE##kml\\\\/slave_$i.kml<\\\\/href>';

      try {
        await executeCommand(
          'sshpass -p $password ssh -t lg$i '
          '\'echo $password | sudo -S sed -i "s/$search/$replace/" '
          '~/earth/kml/slave/myplaces.kml\'',
        );
      } catch (e) {
        debugPrint('Failed to disable refresh on slave $i: $e');
      }
    }
  }

  Future<void> sendKml1() async {
    if (!isConnected) {
      throw Exception('Not connected to LG');
    }

    await _sshController.uploadAsset(
      'assets/kml1.kml',
      '/var/www/html/kml1.kml',
    );

    await Future.delayed(const Duration(milliseconds: 300));

    await executeCommand(
      "echo '\nhttp://${_settingsController.lgHost}:81/kml1.kml' > /var/www/html/kmls.txt",
    );

    await Future.delayed(const Duration(milliseconds: 300));

    await query(
      'flytoview=<LookAt>'
      '<longitude>78.0081</longitude>'
      '<latitude>27.1767</latitude>'
      '<range>30000</range>'
      '<tilt>0</tilt>'
      '<heading>0</heading>'
      '</LookAt>',
    );
  }

  Future<void> sendKml2() async {
    if (!isConnected) {
      throw Exception('Not connected to LG');
    }

    await _sshController.uploadAsset(
      'assets/kml2.kml',
      '/var/www/html/kml2.kml',
    );

    await Future.delayed(const Duration(milliseconds: 300));

    await executeCommand(
      "echo '\nhttp://${_settingsController.lgHost}:81/kml2.kml' > /var/www/html/kmls.txt",
    );

    await Future.delayed(const Duration(milliseconds: 300));

    await query(
      'flytoview=<LookAt>'
      '<longitude>-3.7038</longitude>'
      '<latitude>40.4168</latitude>'
      '<range>1200</range>'
      '<tilt>65</tilt>'
      '<heading>0</heading>'
      '</LookAt>',
    );
  }

  Future<void> clearKmls({bool keepLogos = true}) async {
    if (!isConnected) {
      throw Exception('Not connected to LG');
    }

    await query('exittour=true');
    await Future.delayed(const Duration(milliseconds: 300));

    await executeCommand('> /var/www/html/kmls.txt');
    await Future.delayed(const Duration(milliseconds: 300));

    final logoScreen = getLogoScreen();

    for (int i = 2; i <= screenAmount; i++) {
      if (keepLogos && i == logoScreen) continue;

      final blankKml =
          '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document id="slave_$i">
  </Document>
</kml>''';

      await _sshController.uploadString(
        blankKml,
        '/var/www/html/kml/slave_$i.kml',
      );

      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<void> sendLogoToLeftScreen({
    required String assetPath,
    int? logoScreenNumber,
  }) async {
    if (!isConnected) {
      throw Exception('Not connected to LG');
    }

    screenAmount = _settingsController.lgRigsNum;
    final int targetScreen = logoScreenNumber ?? getLogoScreen();
    final String logoUrl =
        'http://${_settingsController.lgHost}:81/kml/logo.png';

    await _sshController.uploadAsset(assetPath, '/var/www/html/kml/logo.png');

    final logoKml =
        '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>Logos</name>
    <ScreenOverlay>
      <name>Logo</name>
      <Icon>
        <href>$logoUrl</href>
      </Icon>
      <color>ffffffff</color>
      <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY x="0.02" y="0.95" xunits="fraction" yunits="fraction"/>
      <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
      <size x="200" y="160" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
  </Document>
</kml>''';

    await _sshController.uploadString(
      logoKml,
      '/var/www/html/kml/slave_$targetScreen.kml',
    );

    await forceRefresh();
  }

  Future<void> clearLogoFromLeftScreen({int? logoScreenNumber}) async {
    if (!isConnected) {
      throw Exception('Not connected to LG');
    }

    screenAmount = _settingsController.lgRigsNum;
    final int targetScreen = logoScreenNumber ?? getLogoScreen();

    final blankKml =
        '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document id="slave_$targetScreen">
  </Document>
</kml>''';

    await sendKMLToSlave(targetScreen, blankKml);
    await forceRefresh();
  }
}
