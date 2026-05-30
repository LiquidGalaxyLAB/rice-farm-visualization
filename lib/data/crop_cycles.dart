import '../models/crop_cycle.dart';

class CropCycles {
  static const CropCycle kharif = CropCycle(
    season: 'Kharif',
    stages: [
      CropStage(
        name: 'Sowing',
        months: 'June - July',
        description:
            'Seeds are sown in nursery beds with the onset of monsoon rains.',
        color: 'ff00ffff', // yellow
      ),
      CropStage(
        name: 'Transplanting',
        months: 'July - August',
        description:
            'Seedlings are transplanted from nurseries to flooded paddy fields.',
        color: 'ff00ff88', // light green
      ),
      CropStage(
        name: 'Growth',
        months: 'August - September',
        description:
            'Rice plants grow and develop grain heads with continuous water supply.',
        color: 'ff00cc00', // green
      ),
      CropStage(
        name: 'Harvest',
        months: 'October - November',
        description:
            'Mature rice is harvested when grains turn golden and moisture drops.',
        color: 'ff00aaff', // golden/orange
      ),
    ],
  );

  static const CropCycle rabi = CropCycle(
    season: 'Rabi',
    stages: [
      CropStage(
        name: 'Sowing',
        months: 'November - December',
        description:
            'Winter rice is sown in irrigated fields after kharif harvest.',
        color: 'ff00ffff',
      ),
      CropStage(
        name: 'Transplanting',
        months: 'December - January',
        description:
            'Seedlings are moved to main fields in cooler winter conditions.',
        color: 'ff00ff88',
      ),
      CropStage(
        name: 'Growth',
        months: 'January - February',
        description:
            'Crops grow using irrigation as there is minimal rainfall.',
        color: 'ff00cc00',
      ),
      CropStage(
        name: 'Harvest',
        months: 'March - April',
        description:
            'Rabi rice is harvested before the summer heat intensifies.',
        color: 'ff00aaff',
      ),
    ],
  );
}
