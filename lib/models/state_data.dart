class StateData {
  final String name;
  final double latitude;
  final double longitude;
  final double production; // million tonnes
  final double area; // million hectares
  final double yield; // kg per hectare
  final String season; // primary season
  final double rainfall; // avg annual mm
  final double irrigatedPercent; // % area irrigated

  const StateData({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.production,
    required this.area,
    required this.yield,
    required this.season,
    required this.rainfall,
    required this.irrigatedPercent,
  });
}
