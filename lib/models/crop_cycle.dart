class CropStage {
  final String name;
  final String months;
  final String description;
  final String color; // KML color in AABBGGRR format

  const CropStage({
    required this.name,
    required this.months,
    required this.description,
    required this.color,
  });
}

class CropCycle {
  final String season;
  final List<CropStage> stages;

  const CropCycle({required this.season, required this.stages});
}
