import 'package:flutter/foundation.dart';
import 'ssh_controller.dart';
import 'settings_controller.dart';
import '../services/kml_builder_service.dart';

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
  String lastKmlFilename = '';

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
      await detectScreenCount();
      await enableSlaveRefresh();
      await showBranding();
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

  /// Auto-detects the number of screens from the LG rig
  Future<void> detectScreenCount() async {
    try {
      final result = await executeCommand(
        "grep -oP '(?<=DHCP_LG_FRAMES_MAX=).*' personavars.txt",
      );
      final count = int.tryParse(result.trim());
      if (count != null && count > 0) {
        screenAmount = count;
      }
    } catch (e) {
      debugPrint('Could not detect screen count: $e');
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

  int get lastScreen => screenAmount <= 1 ? 1 : (screenAmount / 2).floor() + 1;

  Future<void> sendKMLToSlave(int screen, String content) async {
    if (!isConnected) {
      throw Exception('Not connected to LG');
    }

    try {
      await _sshController.uploadString(
        content,
        '/var/www/html/kml/slave_$screen.kml',
      );
    } catch (e) {
      // Fallback to echo if SFTP fails
      try {
        await executeCommand(
          "echo '$content' > /var/www/html/kml/slave_$screen.kml",
        );
      } catch (e2) {
        debugPrint('Failed to send KML to slave $screen: $e2');
      }
    }
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
    String prefix = 'rice_viz',
  }) async {
    if (!isConnected) {
      await reconnect();
    }

    // Unique name every send -> new md5 in sync_nlc.php ->
    // all screens get a Create and download the fresh KML
    final filename = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.kml';
    lastKmlFilename = filename;

    // Empty the list and remove old files
    await safeExecute('> /var/www/html/kmls.txt');
    await safeExecute('rm -f /var/www/html/kml/${prefix}_*.kml');
    await safeExecute('rm -f /var/www/html/${prefix}_*.kml');

    await _sshController.uploadString(
      kmlContent,
      '/var/www/html/kml/$filename',
    );
    await safeExecute('chmod 644 /var/www/html/kml/$filename');

    await Future.delayed(const Duration(milliseconds: 500));

    await safeExecute(
      'echo "http://${_settingsController.lgHost}:81/kml/$filename" > /var/www/html/kmls.txt',
    );
  }

  /// Uploads an orbit tour KML and starts playing it.
  /// Appends to kmls.txt so the current colored KML stays visible.
  Future<void> startOrbit(String orbitKml) async {
    if (!isConnected) {
      await reconnect();
    }
    final filename = 'orbit_${DateTime.now().millisecondsSinceEpoch}.kml';
    await safeExecute('rm -f /var/www/html/kml/orbit_*.kml');
    await safeExecute('rm -f /var/www/html/orbit_*.kml');
    await _sshController.uploadString(orbitKml, '/var/www/html/kml/$filename');
    await safeExecute('chmod 644 /var/www/html/kml/$filename');
    await Future.delayed(const Duration(milliseconds: 500));
    await safeExecute(
      'echo "http://${_settingsController.lgHost}:81/kml/$filename" >> /var/www/html/kmls.txt',
    );
    // Give screens time to load the tour, then play it
    await Future.delayed(const Duration(milliseconds: 2500));
    await safeExecute('echo "playtour=Orbit" > /tmp/query.txt');
  }

  /// Stops a running orbit tour
  Future<void> stopOrbit() async {
    await safeExecute('echo "exittour=true" > /tmp/query.txt');
  }

  /// Collapses whitespace/newlines and caps length so error banners stay readable.
  String _trimOutput(String input, int maxLen) {
    final collapsed = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    return collapsed.length > maxLen
        ? '${collapsed.substring(0, maxLen)}…'
        : collapsed;
  }

  /// Read-only diagnostic for the kmls.txt delivery pipeline.
  /// Returns '' if all checks pass, otherwise a descriptive error string.
  Future<String> verifyKmlDelivery() async {
    final url = 'http://${_settingsController.lgHost}:81/kml/$lastKmlFilename';
    try {
      final kmlsTxt = await safeExecute('cat /var/www/html/kmls.txt');
      if (!kmlsTxt.contains(lastKmlFilename)) {
        return 'KML ERROR [1/3] kmls.txt does not contain the sent file.\n'
            'Expected: $lastKmlFilename\n'
            'Actual content: "${_trimOutput(kmlsTxt, 120)}"';
      }

      final masterCode = await safeExecute(
        'curl -s -o /dev/null -w "%{http_code}" $url',
      );
      final code = masterCode.trim();
      if (code != '200') {
        final String meaning;
        switch (code) {
          case '403':
            meaning = 'permission denied - Apache cannot read the file';
            break;
          case '404':
            meaning = 'file not found at this path';
            break;
          case '000':
            meaning = 'connection failed - Apache/port 81 not reachable';
            break;
          default:
            meaning = 'unexpected response';
        }
        return 'KML ERROR [2/3] master cannot serve the KML.\n'
            'URL: $url\n'
            'HTTP: $code ($meaning)';
      }

      final password = _settingsController.lgPassword;
      final slaveOutput = await executeCommand(
        'sshpass -p $password ssh -o StrictHostKeyChecking=no -o ConnectTimeout=4 lg2 '
        '"curl -s -o /dev/null -w \'%{http_code}\' $url"',
      );
      if (!slaveOutput.contains('200')) {
        return 'KML ERROR [3/3] slave lg2 cannot download the KML.\n'
            'URL: $url\n'
            'slave response: "${_trimOutput(slaveOutput, 120)}"\n'
            '(master IP unreachable from slave, or curl/ssh issue on rig)';
      }

      debugPrint('KML VERIFY OK: $url served to master and slave');
      return '';
    } catch (e) {
      return 'KML ERROR verify crashed: ${_trimOutput(e.toString(), 200)}';
    }
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

  /// Shows project logo + title on the left slave screen
  Future<void> showBranding() async {
    if (!isConnected) return;

    final logoUrl = 'http://${_settingsController.lgHost}:81/kml/logo.png';

    // Upload project logo
    await _sshController.uploadAsset(
      'assets/logo.png',
      '/var/www/html/kml/logo.png',
    );
    await executeCommand('chmod 644 /var/www/html/kml/logo.png');

    final kmlBuilder = KmlBuilderService();
    final brandingKml = kmlBuilder.buildBrandingOverlay(logoUrl);
    await sendKMLToSlave(firstScreen, brandingKml);
  }

  /// Shows a dashboard image on the right slave screen
  Future<void> showDashboard(String assetPath) async {
    if (!isConnected) return;

    final rightScreen = lastScreen;
    final dashUrl = 'http://${_settingsController.lgHost}:81/kml/dashboard.png';

    // Clear the old dashboard first
    final blankKml =
        '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document id="slave_$rightScreen">
  </Document>
</kml>''';
    await sendKMLToSlave(rightScreen, blankKml);
    await Future.delayed(const Duration(milliseconds: 300));

    // Upload the new dashboard image
    await _sshController.uploadAsset(
      assetPath,
      '/var/www/html/kml/dashboard.png',
    );
    await executeCommand('chmod 644 /var/www/html/kml/dashboard.png');
    await Future.delayed(const Duration(milliseconds: 300));

    // Create ScreenOverlay KML
    final dashKml =
        '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Dashboard</name>
    <ScreenOverlay>
      <name>Stats Dashboard</name>
      <Icon>
        <href>$dashUrl</href>
      </Icon>
      <color>ffffffff</color>
      <overlayXY x="0.5" y="0.5" xunits="fraction" yunits="fraction"/>
      <screenXY x="0.5" y="0.5" xunits="fraction" yunits="fraction"/>
      <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
      <size x="0.53" y="0.89" xunits="fraction" yunits="fraction"/>
    </ScreenOverlay>
  </Document>
</kml>''';

    await sendKMLToSlave(rightScreen, dashKml);
  }

  /// Shows both branding and stats
  /// Shows both branding and dashboard
  Future<void> showSideScreens({
    String dashboardAsset = 'assets/dashboards/dashboard_production.png',
  }) async {
    await showBranding();
    await Future.delayed(const Duration(milliseconds: 500));
    await showDashboard(dashboardAsset);
  }

  Future<void> clearKmls({bool keepLogos = true}) async {
    if (!isConnected) {
      await reconnect();
    }

    await safeExecute('echo "exittour=true" > /tmp/query.txt');
    await Future.delayed(const Duration(milliseconds: 300));

    await safeExecute('> /var/www/html/kmls.txt');
    await safeExecute('rm -f /var/www/html/rice_viz.kml');
    await safeExecute('rm -f /var/www/html/kml/rice_viz_*.kml');
    await safeExecute('rm -f /var/www/html/kml/orbit_*.kml');
    await safeExecute('rm -f /var/www/html/kml/dashboard.png');
    await Future.delayed(const Duration(milliseconds: 300));

    // Clear all slave screens
    for (int i = 2; i <= screenAmount; i++) {
      if (keepLogos && i == firstScreen) continue;
      try {
        await _sshController.uploadString(
          '<?xml version="1.0" encoding="UTF-8"?>\n<kml xmlns="http://www.opengis.net/kml/2.2">\n<Document id="slave_$i">\n</Document>\n</kml>',
          '/var/www/html/kml/slave_$i.kml',
        );
      } catch (e) {
        debugPrint('Failed to clear slave $i: $e');
      }
    }
  }

  /// Relaunches Google Earth on all screens
  Future<void> relaunch() async {
    if (!isConnected) return;

    final pw = _settingsController.lgPassword;
    final user = _settingsController.lgUsername;

    for (var i = screenAmount; i >= 1; i--) {
      try {
        final relaunchCommand =
            """RELAUNCH_CMD="\\
if [ -f /etc/init/lxdm.conf ]; then
  export SERVICE=lxdm
elif [ -f /etc/init/lightdm.conf ]; then
  export SERVICE=lightdm
else
  exit 1
fi
if  [[ \\\$(service \\\$SERVICE status) =~ 'stop' ]]; then
  echo $pw | sudo -S service \\\${SERVICE} start
else
  echo $pw | sudo -S service \\\${SERVICE} restart
fi
" && sshpass -p $pw ssh -x -t lg@lg$i "\$RELAUNCH_CMD\"""";
        await executeCommand(
          '"/home/$user/bin/lg-relaunch" > /home/$user/log.txt',
        );
        await executeCommand(relaunchCommand);
      } catch (e) {
        debugPrint('Failed to relaunch lg$i: $e');
      }
    }
  }

  /// Reboots all LG machines
  Future<void> reboot() async {
    if (!isConnected) return;

    final pw = _settingsController.lgPassword;

    for (var i = screenAmount; i >= 1; i--) {
      try {
        await executeCommand(
          'sshpass -p $pw ssh -t lg$i "echo $pw | sudo -S reboot"',
        );
      } catch (e) {
        debugPrint('Failed to reboot lg$i: $e');
      }
    }
  }

  /// Shuts down all LG machines
  Future<void> shutdown() async {
    if (!isConnected) return;

    final pw = _settingsController.lgPassword;

    for (var i = screenAmount; i >= 1; i--) {
      try {
        await executeCommand(
          'sshpass -p $pw ssh -t lg$i "echo $pw | sudo -S poweroff"',
        );
      } catch (e) {
        debugPrint('Failed to shutdown lg$i: $e');
      }
    }
  }

  /// Hides logo from left screen
  Future<void> hideLogo() async {
    if (!isConnected) return;

    try {
      await _sshController.uploadString(
        '<?xml version="1.0" encoding="UTF-8"?>\n<kml xmlns="http://www.opengis.net/kml/2.2">\n<Document id="slave_$firstScreen">\n</Document>\n</kml>',
        '/var/www/html/kml/slave_$firstScreen.kml',
      );
    } catch (e) {
      debugPrint('Failed to hide logo: $e');
    }
  }
}
