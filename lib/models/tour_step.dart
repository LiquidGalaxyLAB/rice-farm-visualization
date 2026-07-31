class TourStep {
  final String title;
  final String narration;
  final double latitude;
  final double longitude;
  final double range;
  final double tilt;
  final double heading;
  final String? kmlAction; // which KML to show during this step
  final String?
  dashboardKey; // e.g. state name, or 'irrigation:StateName', or 'crop:Kharif:Sowing'

  const TourStep({
    required this.title,
    required this.narration,
    required this.latitude,
    required this.longitude,
    this.range = 5000000,
    this.tilt = 0,
    this.heading = 0,
    this.kmlAction,
    this.dashboardKey,
  });
}
