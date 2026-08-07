import 'package:flutter/foundation.dart';
import 'ssh_controller.dart';
import 'settings_controller.dart';
import '../services/kml_builder_service.dart';
import '../data/rice_states.dart';
import '../data/irrigation_data.dart';
import '../models/state_data.dart';
import '../data/crop_cycles.dart';
import '../data/narration_scripts.dart';

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
  String _lastColoredKml = '';

  bool get isConnected => _sshController.isConnected;
  String? get lastError => _sshController.lastError;

  /// Minimal valid empty KML — used to blank master.kml instead of
  /// leaving a zero-byte file that GE may reject as invalid.
  static const String _emptyKml =
      '<?xml version="1.0" encoding="UTF-8"?>'
      '<kml xmlns="http://www.opengis.net/kml/2.2"><Document></Document></kml>';

  /// One-time permissions setup so per-send chmod is never needed.
  Future<void> _initializePermissions() async {
    final pw = _settingsController.lgPassword;
    await safeExecute(
      'echo $pw | sudo -S chmod 777 /var/www/html/kml && '
      'echo $pw | sudo -S touch /var/www/html/kmls.txt && '
      'echo $pw | sudo -S chmod 777 /var/www/html/kmls.txt',
    );
  }

  /// Enables a 3s refresh on the master.kml NetworkLink on EVERY machine.
  /// All screens (master + slaves) have this link in their myplaces.kml —
  /// with refresh active, any write to master.kml renders on all screens
  /// within 3 seconds (the "data on all screens" architecture).
  /// Idempotent: strips existing refresh tags before adding, handles both
  /// href formats (with and without leading slash).
  Future<void> enableMasterRefresh() async {
    // sed pair: strip any existing refresh, then add a fresh one.
    // %s is replaced per-format below.
    String sedPair(String href, String file) =>
        'sed -i "s|<href>$href</href>'
        '<refreshMode>onInterval</refreshMode>'
        '<refreshInterval>[0-9]*</refreshInterval>|'
        '<href>$href</href>|" $file ; '
        'sed -i "s|<href>$href</href>|'
        '<href>$href</href>'
        '<refreshMode>onInterval</refreshMode>'
        '<refreshInterval>3</refreshInterval>|" $file';

    const hrefSlash = '##LG_PHPIFACE##/kml/master.kml';
    const hrefNoSlash = '##LG_PHPIFACE##kml/master.kml';

    // 1. Master machine (local file)
    try {
      await safeExecute(
        '${sedPair(hrefSlash, '~/earth/kml/master/myplaces.kml')} ; '
        '${sedPair(hrefNoSlash, '~/earth/kml/master/myplaces.kml')}',
      );
    } catch (e) {
      debugPrint('Master refresh on master failed: $e');
    }

    // 2. Every slave machine (remote via ssh)
    final password = _settingsController.lgPassword;
    for (int i = 2; i <= screenAmount; i++) {
      try {
        final inner =
            '${sedPair(hrefSlash, '~/earth/kml/slave/myplaces.kml')} ; '
            '${sedPair(hrefNoSlash, '~/earth/kml/slave/myplaces.kml')}';
        await executeCommand(
          'sshpass -p $password ssh -o StrictHostKeyChecking=no lg@lg$i '
          "'$inner'",
        );
      } catch (e) {
        debugPrint('Master refresh on slave $i failed: $e');
      }
    }
  }

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
      await enableMasterRefresh();
      await _initializePermissions();
      await clearKmls(keepLogos: false); // fresh slate on every connect
      await showBranding(); // then paint the logo clean
    }

    return success;
  }

  Future<void> disconnect() async {
    _sshController.disconnect();
  }

  /// Full reconnect using saved settings (user-facing — purges state).
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

  /// Lightweight session re-establish for mid-operation recovery.
  /// Does NOT purge KMLs or repaint branding — only restores the session.
  Future<bool> _restoreSession() async {
    try {
      _sshController.disconnect();
      await Future.delayed(const Duration(milliseconds: 500));
      return await _sshController.connect(
        host: _settingsController.lgHost,
        port: _settingsController.lgPort,
        username: _settingsController.lgUsername,
        password: _settingsController.lgPassword,
      );
    } catch (e) {
      debugPrint('Session restore failed: $e');
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

  /// Executes a command with session-restore on failure
  Future<String> safeExecute(String command) async {
    try {
      return await executeCommand(command);
    } catch (e) {
      debugPrint('Command failed, restoring session: $e');
      final success = await _restoreSession();
      if (success) {
        return await executeCommand(command);
      }
      rethrow;
    }
  }

  /// Sends query with session-restore on failure
  Future<void> safeQuery(String content) async {
    try {
      await query(content);
    } catch (e) {
      debugPrint('Query failed, restoring session: $e');
      final success = await _restoreSession();
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

  /// Uploads a KML via SFTP to a hidden temp file, then atomically moves
  /// it to the destination. SFTP removes all shell-escaping fragility
  /// (the source of the intermittent failures); the mv guarantees GE's
  /// 3s refresh never reads a half-written file.
  Future<void> _atomicUpload(String content, String destPath) async {
    const tmpPath = '/var/www/html/kml/.upload_tmp.kml';
    await _sshController.uploadString(content, tmpPath);
    await safeExecute('mv $tmpPath $destPath');
  }

  /// Sends a colored KML so it renders on ALL screens:
  /// master.kml — every machine's GE watches this file with a 3s refresh
  /// (set at connect). Also mirrors to rice_viz.kml + kmls.txt for the
  /// sync_nlc path as a second delivery route.
  Future<void> sendKmlToMaster(
    String kmlContent, {
    String prefix = 'rice_viz',
  }) async {
    if (!isConnected) {
      await _restoreSession();
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    lastKmlFilename = 't=$timestamp';
    _lastColoredKml = kmlContent;

    // SFTP upload once, then cp + atomic mv + announce in one channel
    const tmpPath = '/var/www/html/kml/.upload_tmp.kml';
    await _sshController.uploadString(kmlContent, tmpPath);
    await safeExecute(
      'cp $tmpPath /var/www/html/kml/rice_viz.kml ; '
      'mv $tmpPath /var/www/html/kml/master.kml ; '
      "echo 'http://lg1:81/kml/rice_viz.kml?t=$timestamp' > /var/www/html/kmls.txt",
    );
  }

  /// Starts an orbit tour. The tour is merged with the current colored
  /// polygons into master.kml (all screens watch it), so the colors stay
  /// visible while the orbit plays. Also mirrors to orbit.kml + kmls.txt.
  Future<void> startOrbit(String orbitKml) async {
    if (!isConnected) {
      await _restoreSession();
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Merge: colored polygons + orbit tour in a single Document
    String coloredInner = '';
    if (_lastColoredKml.isNotEmpty) {
      final s = _lastColoredKml.indexOf('<Document>');
      final e = _lastColoredKml.lastIndexOf('</Document>');
      if (s != -1 && e != -1) {
        coloredInner = _lastColoredKml.substring(s + '<Document>'.length, e);
      }
    }
    String orbitInner = orbitKml;
    final os = orbitKml.indexOf('<Document>');
    final oe = orbitKml.lastIndexOf('</Document>');
    if (os != -1 && oe != -1) {
      orbitInner = orbitKml.substring(os + '<Document>'.length, oe);
    }

    final combined =
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<kml xmlns="http://www.opengis.net/kml/2.2" '
        'xmlns:gx="http://www.google.com/kml/ext/2.2">'
        '<Document>$coloredInner$orbitInner</Document></kml>';

    // Upload combined -> master.kml (atomic), orbit-only -> orbit.kml
    await _atomicUpload(combined, '/var/www/html/kml/master.kml');
    await _sshController.uploadString(orbitKml, '/var/www/html/kml/orbit.kml');
    await safeExecute(
      "echo 'http://lg1:81/kml/orbit.kml?t=$timestamp' >> /var/www/html/kmls.txt",
    );

    // One refresh cycle (3s) for every screen to load the tour, then play
    await Future.delayed(const Duration(milliseconds: 3500));
    await safeExecute('echo "playtour=Orbit" > /tmp/query.txt');
  }

  /// Stops a running orbit and restores the colored polygons to master.kml
  Future<void> stopOrbit() async {
    await safeExecute('echo "exittour=true" > /tmp/query.txt');
    if (_lastColoredKml.isNotEmpty) {
      try {
        await _atomicUpload(_lastColoredKml, '/var/www/html/kml/master.kml');
      } catch (e) {
        debugPrint('Restore after orbit failed: $e');
      }
    }
  }

  /// Collapses whitespace/newlines and caps length so error banners stay readable.
  String _trimOutput(String input, int maxLen) {
    final collapsed = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    return collapsed.length > maxLen
        ? '${collapsed.substring(0, maxLen)}…'
        : collapsed;
  }

  /// Read-only diagnostic for the KML delivery pipeline.
  /// Returns '' if all checks pass, otherwise a descriptive error string.
  Future<String> verifyKmlDelivery() async {
    try {
      final kmlsTxt = await safeExecute('cat /var/www/html/kmls.txt');
      if (!kmlsTxt.contains(lastKmlFilename)) {
        return 'KML ERROR [1/3] kmls.txt does not contain the sent version.\n'
            'Expected: $lastKmlFilename\n'
            'Actual content: "${_trimOutput(kmlsTxt, 120)}"';
      }

      final url = kmlsTxt.trim().split('\n').first;

      final masterCode = await safeExecute(
        'curl -s -o /dev/null -w "%{http_code}" "$url"',
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
            meaning = 'connection failed - Apache/port 81 not reachable on lg1';
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
        'sshpass -p $password ssh -o StrictHostKeyChecking=no -o ConnectTimeout=4 lg@lg2 '
        '"curl -s -o /dev/null -w \'%{http_code}\' \\"$url\\""',
      );
      if (!slaveOutput.contains('200')) {
        return 'KML ERROR [3/3] slave lg2 cannot download the KML.\n'
            'URL: $url\n'
            'slave response: "${_trimOutput(slaveOutput, 120)}"\n'
            '(lg1 not resolvable from slave, or curl/ssh issue on rig)';
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

    final logoUrl = 'http://lg1:81/kml/logo.png';

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

  /// Shows a dashboard image as an HTML balloon on the right slave screen.
  /// Uploads the PNG once, then renders it full-width via BalloonStyle —
  /// no ScreenOverlay sizing, no aspect-ratio stretching.
  /// Sends a pre-built dashboard balloon KML to the right slave screen.
  int _stateYield(StateData s) => s.yield.toInt();

  String? _irrigationNarrationFor(StateData s) {
    final irr = IrrigationData.stateWise[s.name];
    if (irr == null) return null;
    return '${s.name} receives ${s.rainfall.toInt()} mm of annual rainfall, '
        'with ${s.irrigatedPercent}% of rice area irrigated. '
        'Main sources: tubewells ${irr['tubewell']}%, canals ${irr['canal']}%.';
  }

  String? _narrationFor(String stateName) {
    switch (stateName) {
      case 'West Bengal':
        return NarrationScripts.westBengal;
      case 'Uttar Pradesh':
        return NarrationScripts.uttarPradesh;
      case 'Punjab':
        return NarrationScripts.punjab;
      case 'Andhra Pradesh':
        return NarrationScripts.andhraPradesh;
      case 'Tamil Nadu':
        return NarrationScripts.tamilNadu;
      case 'Odisha':
        return NarrationScripts.odisha;
      case 'Bihar':
        return NarrationScripts.bihar;
      case 'Chhattisgarh':
        return NarrationScripts.chhattisgarh;
      case 'Assam':
        return NarrationScripts.assam;
      case 'Jharkhand':
        return NarrationScripts.jharkhand;
      default:
        return null;
    }
  }

  Future<void> showDashboardBalloon(String balloonKml) async {
    if (!isConnected) return;
    await sendKMLToSlave(lastScreen, balloonKml);
  }

  Future<void> showDashboard(String assetPath) async {
    if (!isConnected) return;

    final kml = KmlBuilderService();
    final file = assetPath.split('/').last.replaceAll('.png', '');

    final national = kml.buildNationalDashboard(
      totalProduction: RiceStates.totalProduction,
      totalArea: RiceStates.totalArea,
      avgYield: RiceStates.averageYield,
      narration: NarrationScripts.indiaOverview,
    );

    String balloon = national;

    // Extract a clean state key by stripping known prefixes
    String stateKey = file
        .replaceFirst('dashboard_', '')
        .replaceFirst('irrigation_', '')
        .replaceAll('_', ' ');

    final isIrrigation = file.contains('irrigation');

    if (file.contains('crop')) {
      balloon = national; // crop handled by showCropDashboard now
    } else if (file == 'dashboard_production' || file == 'dashboard_tour') {
      balloon = national;
    } else if (isIrrigation && stateKey.trim().isEmpty) {
      // Bare "dashboard_irrigation" (entry default) → national for now
      balloon = national;
    } else {
      final matches = RiceStates.states.where(
        (s) => s.name.toLowerCase() == stateKey,
      );
      if (matches.isNotEmpty) {
        final s = matches.first;
        final irr = IrrigationData.stateWise[s.name];
        if (isIrrigation && irr != null) {
          balloon = kml.buildIrrigationDashboard(
            name: s.name,
            canal: (irr['canal'] as num).toDouble(),
            tubewell: (irr['tubewell'] as num).toDouble(),
            tank: (irr['tank'] as num).toDouble(),
            other: (irr['other'] as num).toDouble(),
            lat: s.latitude,
            lon: s.longitude,
            narration: _irrigationNarrationFor(s),
          );
        } else {
          balloon = kml.buildStateDashboard(
            name: s.name,
            production: s.production,
            area: s.area,
            yieldValue: _stateYield(s),
            rainfall: s.rainfall.toInt(),
            irrigatedPercent: s.irrigatedPercent,
            lat: s.latitude,
            lon: s.longitude,
            narration: _narrationFor(s.name),
          );
        }
      }
    }

    await sendKMLToSlave(lastScreen, balloon);
  }

  /// Crop stage dashboard — pass the actual stage.
  Future<void> showCropDashboard({
    required String season,
    required String stageName,
    required String months,
    required String description,
  }) async {
    if (!isConnected) return;
    final kml = KmlBuilderService();
    final balloon = kml.buildCropStageDashboard(
      season: season,
      stageName: stageName,
      months: months,
      description: description,
    );
    await sendKMLToSlave(lastScreen, balloon);
  }

  /// Looks up a stage's details from CropCycles and shows its dashboard.
  Future<void> showCropDashboardByStage(String season, String stageName) async {
    if (!isConnected) return;
    final cycle = season == 'Kharif' ? CropCycles.kharif : CropCycles.rabi;
    final stage = cycle.stages.firstWhere(
      (s) => s.name.toLowerCase() == stageName.toLowerCase(),
      orElse: () => cycle.stages.first,
    );
    await showCropDashboard(
      season: season,
      stageName: stage.name,
      months: stage.months,
      description: stage.description,
    );
  }

  /// State dashboard — production profile.
  Future<void> showStateDashboard(StateData s) async {
    if (!isConnected) return;
    final kml = KmlBuilderService();
    final balloon = kml.buildStateDashboard(
      name: s.name,
      production: s.production,
      area: s.area,
      yieldValue: _stateYield(s),
      rainfall: s.rainfall.toInt(),
      irrigatedPercent: s.irrigatedPercent,
      lat: s.latitude,
      lon: s.longitude,
      narration: _narrationFor(s.name),
    );
    await sendKMLToSlave(lastScreen, balloon);
  }

  /// Irrigation dashboard — source breakdown for a state.
  Future<void> showIrrigationDashboard(StateData s) async {
    if (!isConnected) return;
    final irr = IrrigationData.stateWise[s.name];
    if (irr == null) return showStateDashboard(s);
    final kml = KmlBuilderService();
    final balloon = kml.buildIrrigationDashboard(
      name: s.name,
      canal: (irr['canal'] as num).toDouble(),
      tubewell: (irr['tubewell'] as num).toDouble(),
      tank: (irr['tank'] as num).toDouble(),
      other: (irr['other'] as num).toDouble(),
      lat: s.latitude,
      lon: s.longitude,
      narration: _irrigationNarrationFor(s),
    );
    await sendKMLToSlave(lastScreen, balloon);
  }

  /// National overview dashboard.
  Future<void> showNationalDashboard() async {
    if (!isConnected) return;
    final kml = KmlBuilderService();
    final balloon = kml.buildNationalDashboard(
      totalProduction: RiceStates.totalProduction,
      totalArea: RiceStates.totalArea,
      avgYield: RiceStates.averageYield,
      narration: NarrationScripts.indiaOverview,
    );
    await sendKMLToSlave(lastScreen, balloon);
  }

  /// Shows both branding and dashboard
  Future<void> showSideScreens({
    String dashboardAsset = 'assets/dashboards/dashboard_production.png',
  }) async {
    await showBranding();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Clears all visualization state. Single atomic channel + slave loop.
  Future<void> clearKmls({bool keepLogos = true}) async {
    if (!isConnected) {
      await _restoreSession();
    }
    _lastColoredKml = '';

    await safeExecute(
      'echo "exittour=true" > /tmp/query.txt; '
      '> /var/www/html/kmls.txt; '
      'rm -f /var/www/html/rice_viz.kml; '
      'rm -f /var/www/html/kml/rice_viz.kml; '
      'rm -f /var/www/html/kml/rice_viz_*.kml; '
      'rm -f /var/www/html/kml/orbit.kml; '
      'rm -f /var/www/html/kml/orbit_*.kml; '
      'rm -f /var/www/html/kml/.upload_tmp.kml; '
      'rm -f /var/www/html/kml/dashboard.png; '
      "echo '$_emptyKml' > /var/www/html/kml/master.kml",
    );
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
