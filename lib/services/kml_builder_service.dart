import '../data/rice_states.dart';
import '../data/state_boundaries.dart';
import '../models/state_data.dart';

class KmlBuilderService {
  /// Builds KML with colored 3D polygons for all rice-producing states
  /// Color intensity based on production volume (more = darker green)
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

  /// Builds KML for a specific crop cycle stage
  /// Shows all Kharif states colored by the stage color
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

  /// Builds KML with irrigation/rainfall markers
  String buildIrrigationKml() {
    final states = RiceStates.states;
    String placemarks = '';

    for (final state in states) {
      final coords = StateBoundaries.boundaries[state.name];
      if (coords == null || coords.isEmpty) continue;

      // Color based on rainfall — more rain = more blue
      final blueIntensity = (state.rainfall / 3000 * 255).toInt().clamp(
        50,
        255,
      );
      final color = 'ff${blueIntensity.toRadixString(16).padLeft(2, '0')}8800';

      placemarks += _buildStatePolygon(
        name: state.name,
        coords: coords,
        color: color,
        height: (state.rainfall * 30).toInt(),
        description:
            'Rainfall: ${state.rainfall.toInt()}mm\\n'
            'Irrigated: ${state.irrigatedPercent}%',
      );

      // Add irrigation marker
      placemarks += _buildPlacemark(
        name: '${state.name} irrigation',
        lat: state.latitude,
        lng: state.longitude,
        description:
            'Irrigated: ${state.irrigatedPercent}%\\n'
            'Rainfall: ${state.rainfall.toInt()}mm/year',
      );
    }

    return _wrapInKmlDocument('Irrigation & Rainfall', placemarks);
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

  // ─── Private helpers ───

  String _productionColor(int intensity) {
    // KML color format: AABBGGRR
    // More production = darker green
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
          <color>ff000000</color>
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
