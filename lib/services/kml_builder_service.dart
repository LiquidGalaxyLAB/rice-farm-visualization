import '../data/rice_states.dart';
import '../data/state_boundaries.dart';
import '../data/all_state_boundaries.dart';
import '../models/state_data.dart';

class KmlBuilderService {
  /// Builds KML with colored 3D polygons for top 10 rice states only
  String buildProductionKml() {
    final states = RiceStates.states;
    final maxProduction = states
        .map((s) => s.production)
        .reduce((a, b) => a > b ? a : b);

    String placemarks = '';

    for (final state in states) {
      final coords = StateBoundaries.boundaries[state.name];
      if (coords == null || coords.isEmpty) continue;

      final intensity = (state.production / maxProduction * 255).toInt();
      final color = _productionColor(intensity);
      final height = (state.production / maxProduction * 80000).toInt() + 5000;

      placemarks += _buildStatePolygon(
        name: state.name,
        coords: coords,
        color: color,
        height: height,
        description:
            'Production: ${state.production}M tonnes\\n'
            'Area: ${state.area}M hectares\\n'
            'Yield: ${state.yield.toInt()} kg/ha',
      );
    }

    return _wrapInKmlDocument('Rice Production by State', placemarks);
  }

  /// Builds KML with color gradient for ALL 36 Indian states
  String buildProductionHeatmapKml() {
    final allBoundaries = AllStateBoundaries.boundaries;
    final production = AllStateBoundaries.production;
    final centroids = AllStateBoundaries.centroids;
    final maxProd = production.values.reduce((a, b) => a > b ? a : b);

    String placemarks = '';

    allBoundaries.forEach((stateName, coords) {
      if (coords.isEmpty) return;
      final safeName = stateName.replaceAll('&', '&amp;');

      // final prod = production[safeName] ?? 0.0;
      double prod = production[stateName] ?? 0.0;
      if (prod == 0.0) {
        for (final entry in production.entries) {
          if (entry.key.replaceAll(' ', '') == stateName.replaceAll(' ', '')) {
            prod = entry.value;
            break;
          }
        }
      }
      final ratio = prod / maxProd;

      final String color;
      if (prod <= 0.05) {
        color = 'aa606060';
      } else if (ratio < 0.05) {
        color = 'cc0022dd';
      } else if (ratio < 0.15) {
        color = 'cc0055ff';
      } else if (ratio < 0.30) {
        color = 'cc00aaff';
      } else if (ratio < 0.50) {
        color = 'cc00ddff';
      } else if (ratio < 0.70) {
        color = 'cc00dd88';
      } else {
        color = 'cc00cc00';
      }

      final height = prod > 0.05
          ? (ratio * 80000).toInt().clamp(5000, 80000)
          : 1000;

      placemarks += _buildStatePolygon(
        name: safeName,
        coords: coords,
        color: color,
        height: height,
        description:
            'State: $safeName\\n'
            'Rice Production: ${prod > 0.05 ? "${prod}M tonnes" : "Negligible"}',
      );

      if (prod >= 0.5) {
        // final centroid = centroids[safeName];
        var centroid = centroids[stateName];
        if (centroid == null) {
          for (final entry in centroids.entries) {
            if (entry.key.replaceAll(' ', '') ==
                stateName.replaceAll(' ', '')) {
              centroid = entry.value;
              break;
            }
          }
        }
        if (centroid != null) {
          placemarks += _buildPlacemark(
            name: '${prod}M T',
            lat: centroid[1],
            lng: centroid[0],
            description: '$safeName\\n${prod}M tonnes',
          );
        }
      }
    });

    return _wrapInKmlDocument('India Rice Production Heatmap', placemarks);
  }

  /// Builds KML highlighting a single state with a label
  String buildStateFlyToKml(StateData state) {
    final coords = StateBoundaries.boundaries[state.name];
    if (coords == null || coords.isEmpty) return '';

    final placemark = _buildStatePolygon(
      name: state.name,
      coords: coords,
      color: 'ff00cc44',
      height: 40000,
      description:
          'Production: ${state.production}M tonnes\\n'
          'Area: ${state.area}M hectares\\n'
          'Yield: ${state.yield.toInt()} kg/ha',
    );

    final label = _buildPlacemark(
      name: state.name,
      lat: state.latitude,
      lng: state.longitude,
      description: '${state.production}M tonnes',
    );

    return _wrapInKmlDocument(state.name, placemark + label);
  }

  /// Builds KML highlighting a single state in blue (for irrigation)
  String buildStateBlueKml(StateData state) {
    final coords = StateBoundaries.boundaries[state.name];
    if (coords == null || coords.isEmpty) return '';

    final ratio = (state.rainfall / 3000).clamp(0.0, 1.0);
    final blueVal = (130 + (125 * ratio)).toInt();
    final color = 'cc${blueVal.toRadixString(16).padLeft(2, '0')}2200';

    final placemark = _buildStatePolygon(
      name: state.name,
      coords: coords,
      color: color,
      height: (state.rainfall * 8).toInt().clamp(5000, 60000),
      borderColor: 'ffaa5500',
      description:
          'Rainfall: ${state.rainfall.toInt()}mm/year\\n'
          'Irrigated: ${state.irrigatedPercent}%',
    );

    final label = _buildPlacemark(
      name: '${state.name} - ${state.rainfall.toInt()}mm',
      lat: state.latitude,
      lng: state.longitude,
      description: 'Irrigated: ${state.irrigatedPercent}%',
    );

    return _wrapInKmlDocument('Irrigation: ${state.name}', placemark + label);
  }

  /// Builds KML for a specific crop cycle stage
  String buildCropCycleKml(String stageName, String color) {
    final states = RiceStates.states
        .where((s) => s.season.contains('Kharif'))
        .toList();

    String placemarks = '';

    for (final state in states) {
      final coords = StateBoundaries.boundaries[state.name];
      if (coords == null || coords.isEmpty) continue;

      placemarks += _buildStatePolygon(
        name: '${state.name} - $stageName',
        coords: coords,
        color: color,
        height: 50000,
        description: stageName,
      );
    }

    return _wrapInKmlDocument('Crop Cycle - $stageName', placemarks);
  }

  /// Builds KML with blue rainfall polygons and irrigation type markers
  String buildIrrigationKml() {
    final states = RiceStates.states;
    String placemarks = '';
    String styles = '''
    <Style id="tubewell">
      <IconStyle>
        <color>ff00cc00</color>
        <scale>1.2</scale>
        <Icon><href>http://maps.google.com/mapfiles/kml/shapes/water.png</href></Icon>
      </IconStyle>
      <LabelStyle><color>ffffffff</color><scale>0.8</scale></LabelStyle>
    </Style>
    <Style id="canal">
      <IconStyle>
        <color>ffff8800</color>
        <scale>1.2</scale>
        <Icon><href>http://maps.google.com/mapfiles/kml/shapes/sailing.png</href></Icon>
      </IconStyle>
      <LabelStyle><color>ffffffff</color><scale>0.8</scale></LabelStyle>
    </Style>
    <Style id="raindrop">
      <IconStyle>
        <color>ffff6600</color>
        <scale>1.0</scale>
        <Icon><href>http://maps.google.com/mapfiles/kml/shapes/rainy.png</href></Icon>
      </IconStyle>
      <LabelStyle><color>ffffffff</color><scale>0.7</scale></LabelStyle>
    </Style>
''';

    for (final state in states) {
      final coords = StateBoundaries.boundaries[state.name];
      if (coords == null || coords.isEmpty) continue;

      final ratio = (state.rainfall / 3000).clamp(0.0, 1.0);
      final blueVal = (120 + (135 * ratio)).toInt();
      final greenVal = ((1 - ratio) * 60).toInt();
      final color =
          'cc${blueVal.toRadixString(16).padLeft(2, '0')}${greenVal.toRadixString(16).padLeft(2, '0')}11';
      final height = (state.rainfall * 8).toInt().clamp(5000, 60000);

      placemarks += _buildStatePolygon(
        name: state.name,
        coords: coords,
        color: color,
        height: height,
        description:
            'Rainfall: ${state.rainfall.toInt()}mm/year\\n'
            'Irrigated: ${state.irrigatedPercent}%',
      );

      placemarks += _buildIconPlacemark(
        name: '${state.rainfall.toInt()} mm',
        lat: state.latitude,
        lng: state.longitude,
        altitude: height + 20000,
        styleId: 'raindrop',
        description:
            '${state.name}\\nAnnual rainfall: ${state.rainfall.toInt()} mm',
      );

      if (state.irrigatedPercent > 50) {
        placemarks += _buildIconPlacemark(
          name: 'Tubewell ${state.irrigatedPercent.toInt()}%',
          lat: state.latitude + 0.4,
          lng: state.longitude + 0.6,
          altitude: 0,
          styleId: 'tubewell',
          description: '${state.name}\\nIrrigated: ${state.irrigatedPercent}%',
        );
      }

      if (state.irrigatedPercent > 30) {
        placemarks += _buildIconPlacemark(
          name: 'Canal',
          lat: state.latitude - 0.4,
          lng: state.longitude - 0.6,
          altitude: 0,
          styleId: 'canal',
          description: '${state.name} canal irrigation',
        );
      }
    }

    return _wrapInKmlDocument('Irrigation & Rainfall', styles + placemarks);
  }

  /// Generates a LookAt XML string for flying to a location
  String buildLookAt({
    required double lat,
    required double lng,
    double range = 5000000,
    double tilt = 0,
    double heading = 0,
  }) {
    return 'flytoview=<LookAt>'
        '<longitude>$lng</longitude>'
        '<latitude>$lat</latitude>'
        '<range>$range</range>'
        '<tilt>$tilt</tilt>'
        '<heading>$heading</heading>'
        '<altitudeMode>absolute</altitudeMode>'
        '</LookAt>';
  }

  /// Generates a list of LookAt strings for orbit animation
  List<String> buildOrbitSequence({
    required double lat,
    required double lng,
    double range = 100000,
    double tilt = 60,
    int steps = 36,
  }) {
    final List<String> sequence = [];
    for (int i = 0; i < steps; i++) {
      final heading = (360 / steps) * i;
      sequence.add(
        buildLookAt(
          lat: lat,
          lng: lng,
          range: range,
          tilt: tilt,
          heading: heading,
        ),
      );
    }
    return sequence;
  }

  /// Builds a gx:Tour KML that orbits a point a full 360 degrees
  String buildOrbitTourKml({
    required double lat,
    required double lng,
    double range = 500000,
    double tilt = 60,
  }) {
    String flyTos = '';
    for (int i = 0; i <= 24; i++) {
      final heading = (i * 15) % 360;
      flyTos +=
          '''
      <gx:FlyTo>
        <gx:duration>0.8</gx:duration>
        <gx:flyToMode>smooth</gx:flyToMode>
        <LookAt>
          <longitude>$lng</longitude>
          <latitude>$lat</latitude>
          <range>$range</range>
          <tilt>$tilt</tilt>
          <heading>$heading</heading>
          <altitudeMode>absolute</altitudeMode>
        </LookAt>
      </gx:FlyTo>
''';
    }
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>OrbitDoc</name>
    <gx:Tour>
      <name>Orbit</name>
      <gx:Playlist>
$flyTos
      </gx:Playlist>
    </gx:Tour>
  </Document>
</kml>''';
  }

  /// HTML dashboard balloon that displays a full-width image on the right
  /// slave screen. The image scales to the balloon width and keeps its own
  /// aspect ratio (width:100%; height:auto) — never stretches, never scrolls
  /// horizontally, on any rig resolution.

  /// Builds KML with project logo overlay for left screen
  String buildBrandingOverlay(String logoUrl) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>Branding</name>
    <ScreenOverlay>
      <name>Project Logo</name>
      <Icon>
        <href>$logoUrl</href>
      </Icon>
      <color>ffffffff</color>
      <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY x="0.02" y="0.95" xunits="fraction" yunits="fraction"/>
      <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
       <size x="820" y="782" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
  </Document>
</kml>''';
  }

  // ─── Private helpers ───

  String _productionColor(int intensity) {
    final green = intensity.clamp(80, 255);
    final red = (255 - intensity).clamp(0, 100);
    return 'ff00${green.toRadixString(16).padLeft(2, '0')}${red.toRadixString(16).padLeft(2, '0')}';
  }

  String _buildStatePolygon({
    required String name,
    required List<List<double>> coords,
    required String color,
    required int height,
    String description = '',
    String borderColor = 'ff000000',
  }) {
    final coordString = coords
        .map((c) => '${c[0]},${c[1]},$height')
        .join('\n          ');

    return '''
    <Placemark>
      <name>$name</name>
      <description>$description</description>
      <Style>
        <PolyStyle>
          <color>$color</color>
          <outline>1</outline>
        </PolyStyle>
        <LineStyle>
          <color>$borderColor</color>
          <width>2</width>
        </LineStyle>
      </Style>
      <Polygon>
        <tessellate>1</tessellate>
        <extrude>1</extrude>
        <altitudeMode>absolute</altitudeMode>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
          $coordString
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
''';
  }

  String _buildPlacemark({
    required String name,
    required double lat,
    required double lng,
    String description = '',
  }) {
    return '''
    <Placemark>
      <name>$name</name>
      <description>$description</description>
      <Point>
        <coordinates>$lng,$lat,0</coordinates>
      </Point>
    </Placemark>
''';
  }

  String _buildIconPlacemark({
    required String name,
    required double lat,
    required double lng,
    required double altitude,
    required String styleId,
    String description = '',
  }) {
    return '''
    <Placemark>
      <name>$name</name>
      <description>$description</description>
      <styleUrl>#$styleId</styleUrl>
      <Point>
        <altitudeMode>absolute</altitudeMode>
        <coordinates>$lng,$lat,$altitude</coordinates>
      </Point>
    </Placemark>
''';
  }

  String _wrapInKmlDocument(String docName, String content) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
  <name>$docName</name>
$content
</Document>
</kml>''';
  }

  // ============================================================
  // HTML DASHBOARD BALLOONS
  // ============================================================

  /// Wraps balloon content in a KML document (matches her wrapInKmlDocument).
  String _wrapBalloon(String content, String name) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>$name</name>
$content
  </Document>
</kml>''';
  }

  /// Common anti-blink script (verbatim from the approved approach).
  String _antiBlink(String bId) =>
      '''
          <script>
            var bId = '$bId';
            window.onload = function() {
              if(localStorage.getItem('lg_bId') === bId) {
                var pos = localStorage.getItem('lg_sPos');
                if (pos) window.scrollTo(0, parseInt(pos, 10));
              } else {
                localStorage.setItem('lg_bId', bId);
                localStorage.setItem('lg_sPos', 0);
              }
              setInterval(function() {
                var pos = window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop || 0;
                localStorage.setItem('lg_sPos', pos);
              }, 100);
            };
          </script>''';

  /// A single stat card cell (used inside the cards row).
  String _statCard(String value, String label, String accent) =>
      '''
                      <td width="25%" align="center" valign="top" style="padding:10px;">
                        <table width="100%" cellpadding="12" cellspacing="0" style="background-color:#161b22;border:1px solid #30363d;border-radius:12px;">
                          <tr><td align="center" style="border-top:4px solid $accent;border-radius:2px;">
                            <span style="font-size:30px;font-weight:bold;color:#ffffff;">$value</span><br>
                            <span style="font-size:13px;color:#8b949e;">$label</span>
                          </td></tr>
                        </table>
                      </td>''';

  /// Builds a balloon with a header + a row of stat cards.
  String _dashboardShell({
    required String bId,
    required String emoji,
    required String title,
    required String subtitle,
    required String cardsRow,
    String? bottomSection,
    String headerBg = '#0F766E',
    String subtitleColor = '#ccfbf1',
    double lat = 22.0,
    double lon = 82.0,
  }) {
    final bottom = (bottomSection == null || bottomSection.isEmpty)
        ? ''
        : '''
              <tr bgcolor="#1e293b">
                <td style="padding:20px;border-top:2px solid #334155;border-bottom-left-radius:16px;border-bottom-right-radius:16px;">
                  $bottomSection
                </td>
              </tr>''';

    final content =
        '''
    <Style id="dash_style">
      <IconStyle><scale>0</scale></IconStyle>
      <BalloonStyle>
        <textColor>ffffffff</textColor>
        <bgColor>ff17110d</bgColor>
        <text><![CDATA[
${_antiBlink(bId)}
          <div style="font-family:Arial,sans-serif;width:700px;padding:16px;box-sizing:border-box;background-color:#0d1117;color:#ffffff;">
            <table width="100%" cellpadding="0" cellspacing="0" style="border:2px solid #334155;border-collapse:collapse;border-radius:16px;background-color:#0d1117;">
              <tr bgcolor="$headerBg">
                <td style="padding:20px;border-top-left-radius:16px;border-top-right-radius:16px;">
                  <span style="color:white;font-size:26px;font-weight:bold;">$emoji $title</span>
                  <br><br>
                  <span style="color:$subtitleColor;font-size:15px;">$subtitle</span>
                </td>
              </tr>
              <tr>
                <td style="padding:16px;">
                  <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                      $cardsRow
                    </tr>
                  </table>
                </td>
              </tr>
              $bottom
            </table>
          </div>
        ]]></text>
      </BalloonStyle>
    </Style>
    <Placemark id="dash_placemark">
      <name>Dashboard</name>
      <styleUrl>#dash_style</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point><coordinates>$lon,$lat,0</coordinates></Point>
    </Placemark>''';

    return _wrapBalloon(content, 'Dashboard');
  }

  /// A simple progress bar row for the bottom section.
  String _barRow(String label, double percent, String color) {
    final pct = percent.clamp(0, 100).toStringAsFixed(1);
    return '''
                  <tr>
                    <td style="padding:6px 0;color:#e2e8f0;font-size:14px;" width="35%">$label</td>
                    <td style="padding:6px 0;" width="50%">
                      <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#0d1117;border-radius:6px;"><tr>
                        <td width="$pct%" style="background-color:$color;height:14px;border-radius:6px;">&nbsp;</td>
                        <td>&nbsp;</td>
                      </tr></table>
                    </td>
                    <td style="padding:6px 0 6px 10px;color:#ffffff;font-size:14px;font-weight:bold;" width="15%">$pct%</td>
                  </tr>''';
  }

  // ---------- PER-FEATURE BUILDERS ----------

  /// State dashboard — regions "Fly to" (production profile of one state).
  String buildStateDashboard({
    required String name,
    required double production,
    required double area,
    required int yieldValue,
    required int rainfall,
    required double irrigatedPercent,
    required double lat,
    required double lon,
  }) {
    final cards =
        _statCard('${production.toStringAsFixed(1)}M', 'Tonnes', '#22c55e') +
        _statCard('${area.toStringAsFixed(1)}M', 'Hectares', '#3b82f6') +
        _statCard('$yieldValue', 'kg/ha', '#eab308') +
        _statCard('${rainfall}mm', 'Rainfall', '#06b6d4');

    final bottom =
        '''
                  <span style="font-size:20px;color:#e2e8f0;font-weight:bold;display:block;margin-bottom:14px;">&#128167; Irrigation Coverage</span>
                  <table width="100%" cellpadding="0" cellspacing="0">
                    ${_barRow('Irrigated Area', irrigatedPercent, '#22c55e')}
                  </table>''';

    return _dashboardShell(
      bId: 'state_$name',
      emoji: '&#127806;',
      title: name,
      subtitle: 'Rice Production Profile',
      cardsRow: cards,
      bottomSection: bottom,
      lat: lat,
      lon: lon,
    );
  }

  /// National overview — regions "Show all".
  String buildNationalDashboard({
    required double totalProduction,
    required double totalArea,
    required double avgYield,
  }) {
    final cards =
        _statCard(
          '${totalProduction.toStringAsFixed(1)}M',
          'Total Tonnes',
          '#22c55e',
        ) +
        _statCard(
          '${totalArea.toStringAsFixed(1)}M',
          'Total Hectares',
          '#3b82f6',
        ) +
        _statCard('${avgYield.toStringAsFixed(0)}', 'Avg kg/ha', '#eab308') +
        _statCard('10', 'Top States', '#a855f7');

    return _dashboardShell(
      bId: 'national_overview',
      emoji: '&#127470;&#127475;',
      title: 'India Rice Production',
      subtitle: 'National Overview • Top 10 States',
      cardsRow: cards,
    );
  }

  /// Crop cycle stage dashboard.
  String buildCropStageDashboard({
    required String season,
    required String stageName,
    required String months,
    required String description,
  }) {
    final cards =
        _statCard(season, 'Season', '#22c55e') +
        _statCard(stageName, 'Stage', '#eab308') +
        _statCard(months.split(' - ').first, 'Starts', '#3b82f6') +
        _statCard(months.split(' - ').last, 'Ends', '#06b6d4');

    final bottom = '''
                  <span style="font-size:18px;color:#e2e8f0;font-weight:bold;display:block;margin-bottom:10px;">&#128220; About this stage</span>
                  <span style="font-size:15px;color:#cbd5e1;line-height:1.6;">$description</span>''';

    return _dashboardShell(
      bId: 'crop_$season$stageName',
      emoji: '&#127807;',
      title: '$stageName',
      subtitle: '$season Season • $months',
      cardsRow: cards,
      bottomSection: bottom,
      headerBg: '#166534',
      subtitleColor: '#bbf7d0',
    );
  }

  /// Irrigation dashboard — per state source breakdown.
  String buildIrrigationDashboard({
    required String name,
    required double canal,
    required double tubewell,
    required double tank,
    required double other,
    required double lat,
    required double lon,
  }) {
    final cards =
        _statCard('${tubewell.toStringAsFixed(0)}%', 'Tubewell', '#3b82f6') +
        _statCard('${canal.toStringAsFixed(0)}%', 'Canal', '#06b6d4') +
        _statCard('${tank.toStringAsFixed(0)}%', 'Tank', '#a855f7') +
        _statCard('${other.toStringAsFixed(0)}%', 'Other', '#8b949e');

    final bottom =
        '''
                  <span style="font-size:20px;color:#e2e8f0;font-weight:bold;display:block;margin-bottom:14px;">&#128167; Irrigation Sources</span>
                  <table width="100%" cellpadding="0" cellspacing="0">
                    ${_barRow('Tubewell', tubewell, '#3b82f6')}
                    ${_barRow('Canal', canal, '#06b6d4')}
                    ${_barRow('Tank', tank, '#a855f7')}
                    ${_barRow('Other', other, '#64748b')}
                  </table>''';

    return _dashboardShell(
      bId: 'irrigation_$name',
      emoji: '&#128167;',
      title: name,
      subtitle: 'Irrigation Source Breakdown',
      cardsRow: cards,
      bottomSection: bottom,
      headerBg: '#0e7490',
      subtitleColor: '#cffafe',
      lat: lat,
      lon: lon,
    );
  }
}
