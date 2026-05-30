import '../models/state_data.dart';

class RiceStates {
  static const List<StateData> states = [
    StateData(
      name: 'West Bengal',
      latitude: 22.9868,
      longitude: 87.8550,
      production: 15.75,
      area: 5.46,
      yield: 2884,
      season: 'Kharif',
      rainfall: 1750,
      irrigatedPercent: 55.2,
    ),
    StateData(
      name: 'Uttar Pradesh',
      latitude: 26.8467,
      longitude: 80.9462,
      production: 14.53,
      area: 5.87,
      yield: 2475,
      season: 'Kharif',
      rainfall: 1025,
      irrigatedPercent: 76.1,
    ),
    StateData(
      name: 'Punjab',
      latitude: 31.1471,
      longitude: 75.3412,
      production: 13.38,
      area: 3.10,
      yield: 4316,
      season: 'Kharif',
      rainfall: 649,
      irrigatedPercent: 98.8,
    ),
    StateData(
      name: 'Andhra Pradesh',
      latitude: 15.9129,
      longitude: 79.7400,
      production: 12.80,
      area: 3.84,
      yield: 3333,
      season: 'Kharif & Rabi',
      rainfall: 966,
      irrigatedPercent: 58.4,
    ),
    StateData(
      name: 'Tamil Nadu',
      latitude: 11.1271,
      longitude: 78.6569,
      production: 7.83,
      area: 2.04,
      yield: 3838,
      season: 'Rabi',
      rainfall: 998,
      irrigatedPercent: 62.3,
    ),
    StateData(
      name: 'Odisha',
      latitude: 20.9517,
      longitude: 85.0985,
      production: 7.19,
      area: 3.71,
      yield: 1938,
      season: 'Kharif',
      rainfall: 1489,
      irrigatedPercent: 34.7,
    ),
    StateData(
      name: 'Bihar',
      latitude: 25.0961,
      longitude: 85.3131,
      production: 6.85,
      area: 3.21,
      yield: 2134,
      season: 'Kharif',
      rainfall: 1326,
      irrigatedPercent: 61.5,
    ),
    StateData(
      name: 'Chhattisgarh',
      latitude: 21.2787,
      longitude: 81.8661,
      production: 6.42,
      area: 3.82,
      yield: 1681,
      season: 'Kharif',
      rainfall: 1292,
      irrigatedPercent: 26.3,
    ),
    StateData(
      name: 'Assam',
      latitude: 26.2006,
      longitude: 92.9376,
      production: 5.41,
      area: 2.54,
      yield: 2130,
      season: 'Kharif',
      rainfall: 2818,
      irrigatedPercent: 12.8,
    ),
    StateData(
      name: 'Jharkhand',
      latitude: 23.6102,
      longitude: 85.2799,
      production: 3.92,
      area: 1.78,
      yield: 2202,
      season: 'Kharif',
      rainfall: 1376,
      irrigatedPercent: 18.9,
    ),
  ];

  static double get totalProduction =>
      states.fold(0, (sum, s) => sum + s.production);

  static double get totalArea => states.fold(0, (sum, s) => sum + s.area);

  static double get averageYield =>
      totalProduction * 1000000 / (totalArea * 1000000);
}
