// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // SharedPreferences keys
  static const kLanguageKey    = 'selected_language';
  static const kFarmerName     = 'farmer_name';
  static const kFarmerDistrict = 'farmer_district';
  static const kVoiceEnabled   = 'voice_enabled';
  static const kOfflineMode    = 'offline_mode';
  static const kTextSize       = 'text_size';

  // App strings
  static const appName   = 'KrishiAvalokan';
  static const taglineHi = 'Samjho, Seekho, Ugao';
  static const taglineEn = 'Understand, Learn, Grow';
  static const krishiini = 'KRISHIAVALOKAN INITIATIVE';

  // Diagnosis steps
  static const totalSteps = 4;

  // ── Backend ────────────────────────────────────────────────────────────────
  // Replace with your deployed backend URL.
  static const backendBaseUrl = 'http://192.168.0.173:8000';
  static const analyzeEndpoint = '$backendBaseUrl/diagnose';
  static const connectTimeoutMs = 12000;
  static const receiveTimeoutMs = 20000;
}

/// All supported regional languages
class AppLanguages {
  AppLanguages._();

  static const List<Map<String, String>> languages = [
    {'name': 'हिंदी',    'code': 'hi', 'english': 'Hindi'},
    {'name': 'मराठी',   'code': 'mr', 'english': 'Marathi'},
    {'name': 'తెలుగు',  'code': 'te', 'english': 'Telugu'},
    {'name': 'ಕನ್ನಡ',  'code': 'kn', 'english': 'Kannada'},
    {'name': 'தமிழ்',   'code': 'ta', 'english': 'Tamil'},
    {'name': 'বাংলা',    'code': 'bn', 'english': 'Bengali'},
    {'name': 'ਪੰਜਾਬੀ',  'code': 'pa', 'english': 'Punjabi'},
    {'name': 'ગુજરાતી', 'code': 'gu', 'english': 'Gujarati'},
    {'name': 'English',  'code': 'en', 'english': 'English'},
  ];
}

/// Crop list with emoji icons
class AppCrops {
  AppCrops._();

  static const List<Map<String, String>> crops = [
    {'name': 'Gehu',    'label': 'गेहू / Wheat',     'emoji': '🌾'},
    {'name': 'Dhan',    'label': 'धान / Rice',        'emoji': '🌾'},
    {'name': 'Kapas',   'label': 'कपास / Cotton',     'emoji': '🌿'},
    {'name': 'Makka',   'label': 'मक्का / Maize',     'emoji': '🌽'},
    {'name': 'Soybean', 'label': 'सोयाबीन / Soybean', 'emoji': '🫘'},
    {'name': 'Tur',     'label': 'तूर / Pigeon Pea',  'emoji': '🌱'},
    {'name': 'Bajra',   'label': 'बाजरा / Millet',    'emoji': '🌿'},
    {'name': 'Ganna',   'label': 'गन्ना / Sugarcane', 'emoji': '🎋'},
  ];
}

/// Indian states + some districts for mock
class AppLocations {
  AppLocations._();

  static const Map<String, List<String>> statesDistricts = {
    'Maharashtra': [
      'Pune', 
      'Nagpur', 
      'Nashik', 
      'Chhatrapati Sambhajinagar', // Fixed: Geocoding usually returns the new name
      'Amravati', 
      'Yavatmal',
      'Mumbai'
    ],
    'Punjab': ['Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala', 'Bathinda'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Varanasi', 'Agra', 'Meerut', 'Gorakhpur'],
    'Madhya Pradesh': ['Bhopal', 'Indore', 'Gwalior', 'Jabalpur', 'Rewa'],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Bikaner', 'Kota'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar'],
    'Andhra Pradesh': ['Visakhapatnam', 'Vijayawada', 'Guntur', 'Kurnool', 'Tirupati'],
    'Karnataka': ['Bengaluru', 'Mysuru', 'Hubli-Dharwad', 'Belagavi'], // Fixed: Bengaluru name
    'Goa': ['North Goa', 'South Goa']
  };

  /// Approximate centre-point coordinates for known districts.
  /// Used when the user picks from the dropdown (no GPS).
  /// Falls back to state capital coords if district not listed.
  static const Map<String, Map<String, double>> districtCoords = {
    // Maharashtra
    'Pune':        {'lat': 18.5204, 'lon': 73.8567},
    'Nagpur':      {'lat': 21.1458, 'lon': 79.0882},
    'Nashik':      {'lat': 19.9975, 'lon': 73.7898},
    'Aurangabad':  {'lat': 19.8762, 'lon': 75.3433},
    'Amravati':    {'lat': 20.9374, 'lon': 77.7796},
    'Yavatmal':    {'lat': 20.3888, 'lon': 78.1204},
    // Punjab
    'Ludhiana':    {'lat': 30.9010, 'lon': 75.8573},
    'Amritsar':    {'lat': 31.6340, 'lon': 74.8723},
    'Jalandhar':   {'lat': 31.3260, 'lon': 75.5762},
    'Patiala':     {'lat': 30.3398, 'lon': 76.3869},
    'Bathinda':    {'lat': 30.2110, 'lon': 74.9455},
    // Uttar Pradesh
    'Lucknow':     {'lat': 26.8467, 'lon': 80.9462},
    'Kanpur':      {'lat': 26.4499, 'lon': 80.3319},
    'Varanasi':    {'lat': 25.3176, 'lon': 82.9739},
    'Agra':        {'lat': 27.1767, 'lon': 78.0081},
    'Meerut':      {'lat': 28.9845, 'lon': 77.7064},
    'Gorakhpur':   {'lat': 26.7606, 'lon': 83.3732},
    // Madhya Pradesh
    'Bhopal':      {'lat': 23.2599, 'lon': 77.4126},
    'Indore':      {'lat': 22.7196, 'lon': 75.8577},
    'Gwalior':     {'lat': 26.2183, 'lon': 78.1828},
    'Jabalpur':    {'lat': 23.1815, 'lon': 79.9864},
    'Rewa':        {'lat': 24.5362, 'lon': 81.2960},
    // Rajasthan
    'Jaipur':      {'lat': 26.9124, 'lon': 75.7873},
    'Jodhpur':     {'lat': 26.2389, 'lon': 73.0243},
    'Udaipur':     {'lat': 24.5854, 'lon': 73.7125},
    'Bikaner':     {'lat': 28.0229, 'lon': 73.3119},
    'Kota':        {'lat': 25.2138, 'lon': 75.8648},
    // Gujarat
    'Ahmedabad':   {'lat': 23.0225, 'lon': 72.5714},
    'Surat':       {'lat': 21.1702, 'lon': 72.8311},
    'Vadodara':    {'lat': 22.3072, 'lon': 73.1812},
    'Rajkot':      {'lat': 22.3039, 'lon': 70.8022},
    'Bhavnagar':   {'lat': 21.7645, 'lon': 72.1519},
    // Andhra Pradesh
    'Visakhapatnam': {'lat': 17.6868, 'lon': 83.2185},
    'Vijayawada':  {'lat': 16.5062, 'lon': 80.6480},
    'Guntur':      {'lat': 16.3067, 'lon': 80.4365},
    'Kurnool':     {'lat': 15.8281, 'lon': 78.0373},
    'Tirupati':    {'lat': 13.6288, 'lon': 79.4192},
    // Karnataka
    'Bengaluru':   {'lat': 12.9716, 'lon': 77.5946},
    'Mysuru':      {'lat': 12.2958, 'lon': 76.6394},
    'Hubli':       {'lat': 15.3647, 'lon': 75.1240},
    'Dharwad':     {'lat': 15.4589, 'lon': 75.0078},
    'Belagavi':    {'lat': 15.8497, 'lon': 74.4977},
  };

  /// Returns coords for a district, or [0.0, 0.0] if not found.
  static (double lat, double lon) coordsFor(String district) {
    final c = districtCoords[district];
    if (c == null) return (0.0, 0.0);
    return (c['lat']!, c['lon']!);
  }
}

/// Symptom list
class AppSymptoms {
  AppSymptoms._();

  static const List<Map<String, String>> symptoms = [
    {
      'key':   'drought',
      'emoji': '🏜️',
      'title': 'Sukha / Drought Stress',
      'desc':  'Plants wilting, leaves curling, dry soil'
    },
    {
      'key':   'waterlogging',
      'emoji': '💧',
      'title': 'Paani Bhari / Waterlogging',
      'desc':  'Roots rotting, yellow leaves near base'
    },
    {
      'key':   'nutrient',
      'emoji': '🟡',
      'title': 'Patta Peela / Nutrient Deficiency',
      'desc':  'Yellowing leaves, stunted growth'
    },
    {
      'key':   'pest',
      'emoji': '🐛',
      'title': 'Keede / Pest Damage',
      'desc':  'Holes in leaves, visible insects'
    },
    {
      'key':   'fungal',
      'emoji': '🍂',
      'title': 'Sada / Fungal Disease',
      'desc':  'Brown or black spots, mold on stems'
    },
    {
      'key':   'heat',
      'emoji': '🌡️',
      'title': 'Garmi / Heat Stress',
      'desc':  'Leaf scorch, premature fruit drop'
    },
  ];
}