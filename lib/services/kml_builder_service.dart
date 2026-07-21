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
      final height = (state.production / maxProduction * 200000).toInt();

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
          ? (ratio * 300000).toInt().clamp(10000, 300000)
          : 2000;

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
      height: 100000,
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
      height: (state.rainfall * 20).toInt().clamp(30000, 200000),
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
      final height = (state.rainfall * 25).toInt();

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
        '<altitudeMode>relativeToGround</altitudeMode>'
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
          <altitudeMode>relativeToGround</altitudeMode>
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
      <size x="520" y="300" xunits="pixels" yunits="pixels"/>
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
        <extrude>1</extrude>
        <altitudeMode>relativeToGround</altitudeMode>
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
        <altitudeMode>relativeToGround</altitudeMode>
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
}
