class NarrationScripts {
  static const String indiaOverview =
      'India is the world\'s second largest rice producer, contributing over 20 percent of global output. Rice is cultivated across diverse agro-climatic zones from Punjab in the north to Tamil Nadu in the south.';

  static const String westBengal =
      'West Bengal is India\'s largest rice producing state with over 15 million tonnes annually. The fertile Gangetic plains and abundant rainfall make it ideal for paddy cultivation.';

  static const String uttarPradesh =
      'Uttar Pradesh ranks second in rice production. The vast Indo-Gangetic plains and extensive canal irrigation support large-scale rice farming across the state.';

  static const String punjab =
      'Punjab is known as India\'s granary with the highest rice yield per hectare. Nearly 99 percent of its rice area is irrigated, making it the most efficient rice producing state.';

  static const String andhraPradesh =
      'Andhra Pradesh grows rice in both Kharif and Rabi seasons, supported by the Krishna and Godavari river deltas. It is a major contributor to India\'s rice exports.';

  static const String tamilNadu =
      'Tamil Nadu is unique for growing rice primarily in the Rabi season. The Cauvery delta region, known as the rice bowl of Tamil Nadu, drives most of its production.';

  static const String odisha =
      'Odisha\'s rice cultivation is largely rain-fed with lower yields compared to irrigated states. However, rice is the lifeline crop for the majority of its farming population.';

  static const String bihar =
      'Bihar produces significant quantities of rice in the north Gangetic plains. Frequent flooding both aids and challenges rice cultivation in the state.';

  static const String chhattisgarh =
      'Chhattisgarh is known as the rice bowl of central India. Most farming is rain-fed with traditional varieties grown across its tribal heartland.';

  static const String assam =
      'Assam receives the highest rainfall among major rice states. Rice is grown in the Brahmaputra valley plains, with unique varieties adapted to flood-prone conditions.';

  static const String jharkhand =
      'Jharkhand\'s rice farming is predominantly rain-fed on the Chota Nagpur plateau. Low irrigation coverage limits yields but rice remains the primary food crop.';

  static const String irrigationOverview =
      'India\'s rice production depends heavily on water. States like Punjab rely almost entirely on irrigation while others like Assam and Odisha depend on monsoon rainfall.';

  static const String cropCycleOverview =
      'Rice follows a seasonal cycle driven by the monsoon. The main Kharif season runs from June to November, while the secondary Rabi season runs from November to April in select southern states.';

  static const String tourClosing =
      'As we look across India\'s vast rice belt, we see a story of diversity. From the irrigated fields of Punjab to the rain-fed paddies of Odisha, rice connects millions of farmers and feeds over a billion people.';

  static const List<Map<String, dynamic>> riceBeltTour = [
    {
      'title': 'India Overview',
      'narration': indiaOverview,
      'lat': 22.0,
      'lng': 82.0,
      'range': 5000000.0,
      'tilt': 0.0,
      'heading': 0.0,
      'kmlAction': 'production',
    },
    {
      'title': 'West Bengal',
      'narration': westBengal,
      'lat': 22.9868,
      'lng': 87.8550,
      'range': 800000.0,
      'tilt': 45.0,
      'heading': 0.0,
      'kmlAction': 'state',
    },
    {
      'title': 'Punjab',
      'narration': punjab,
      'lat': 31.1471,
      'lng': 75.3412,
      'range': 800000.0,
      'tilt': 45.0,
      'heading': 0.0,
      'kmlAction': 'state',
    },
    {
      'title': 'Uttar Pradesh',
      'narration': uttarPradesh,
      'lat': 26.8467,
      'lng': 80.9462,
      'range': 800000.0,
      'tilt': 45.0,
      'heading': 0.0,
      'kmlAction': 'state',
    },
    {
      'title': 'Tamil Nadu',
      'narration': tamilNadu,
      'lat': 11.1271,
      'lng': 78.6569,
      'range': 800000.0,
      'tilt': 45.0,
      'heading': 0.0,
      'kmlAction': 'state',
    },
    {
      'title': 'Crop Cycle',
      'narration': cropCycleOverview,
      'lat': 22.0,
      'lng': 82.0,
      'range': 4000000.0,
      'tilt': 20.0,
      'heading': 0.0,
      'kmlAction': 'production',
    },
    {
      'title': 'Tour Complete',
      'narration': tourClosing,
      'lat': 22.0,
      'lng': 82.0,
      'range': 5000000.0,
      'tilt': 0.0,
      'heading': 0.0,
      'kmlAction': 'production',
    },
  ];

  static const List<Map<String, dynamic>> irrigationTour = [
    {
      'title': 'Irrigation Overview',
      'narration': irrigationOverview,
      'lat': 22.0,
      'lng': 82.0,
      'range': 5000000.0,
      'tilt': 0.0,
      'heading': 0.0,
      'kmlAction': 'irrigation',
    },
    {
      'title': 'Punjab',
      'narration':
          'Punjab has the highest irrigation coverage in India at nearly 99 percent. With only 649 millimeters of annual rainfall, the state depends almost entirely on tubewells and canals to sustain its massive rice production.',
      'lat': 31.1471,
      'lng': 75.3412,
      'range': 800000.0,
      'tilt': 45.0,
      'heading': 0.0,
      'kmlAction': 'state',
    },
    {
      'title': 'Uttar Pradesh',
      'narration':
          'Uttar Pradesh uses a combination of tubewells and canal networks to irrigate over 76 percent of its rice area. The extensive Gangetic canal system built during the British era still forms the backbone of irrigation here.',
      'lat': 26.8467,
      'lng': 80.9462,
      'range': 800000.0,
      'tilt': 45.0,
      'heading': 0.0,
      'kmlAction': 'state',
    },
    {
      'title': 'Assam',
      'narration':
          'Assam receives the highest rainfall among all rice states at over 2800 millimeters annually. Yet only 13 percent of its area is irrigated. The Brahmaputra floods both nourish and devastate its paddy fields each year.',
      'lat': 26.2006,
      'lng': 92.9376,
      'range': 800000.0,
      'tilt': 45.0,
      'heading': 0.0,
      'kmlAction': 'state',
    },
    {
      'title': 'Tamil Nadu',
      'narration':
          'Tamil Nadu relies heavily on tank irrigation, a traditional system of interconnected reservoirs. The Cauvery delta region uses a mix of canals, tanks, and tubewells to support its unique Rabi season rice cultivation.',
      'lat': 11.1271,
      'lng': 78.6569,
      'range': 800000.0,
      'tilt': 45.0,
      'heading': 0.0,
      'kmlAction': 'state',
    },
  ];

  static const List<Map<String, dynamic>> seasonalFarmingTour = [
    {
      'title': 'Seasonal Overview',
      'narration': cropCycleOverview,
      'lat': 22.0,
      'lng': 82.0,
      'range': 5000000.0,
      'tilt': 0.0,
      'heading': 0.0,
      'kmlAction': 'sowing',
    },
    {
      'title': 'Sowing Season',
      'narration':
          'The rice season begins in June and July with the arrival of the monsoon. Farmers prepare nursery beds and sow seeds. Across India, millions of small paddy fields are flooded and seeded as the rains arrive.',
      'lat': 22.0,
      'lng': 82.0,
      'range': 4000000.0,
      'tilt': 20.0,
      'heading': 0.0,
      'kmlAction': 'sowing',
    },
    {
      'title': 'Transplanting',
      'narration':
          'In July and August, young seedlings are carefully uprooted from nursery beds and transplanted into flooded paddy fields. This labor-intensive process is still done by hand across most of India.',
      'lat': 22.0,
      'lng': 82.0,
      'range': 4000000.0,
      'tilt': 20.0,
      'heading': 30.0,
      'kmlAction': 'transplanting',
    },
    {
      'title': 'Growth Period',
      'narration':
          'From August to September, the rice plants enter their growth phase. The fields remain flooded as the plants develop grain heads. This is when the landscape turns a lush, vibrant green across the rice belt.',
      'lat': 22.0,
      'lng': 82.0,
      'range': 4000000.0,
      'tilt': 20.0,
      'heading': 60.0,
      'kmlAction': 'growth',
    },
    {
      'title': 'Harvest Time',
      'narration':
          'October and November bring the harvest. The fields turn golden as the grain matures. Farmers drain the paddies and harvest the rice, completing one cycle of India\'s most important food crop.',
      'lat': 22.0,
      'lng': 82.0,
      'range': 4000000.0,
      'tilt': 20.0,
      'heading': 90.0,
      'kmlAction': 'harvest',
    },
  ];
}
