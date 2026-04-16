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

  // Diagnosis steps
  static const totalSteps = 4;
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
    'Maharashtra':  ['Pune', 'Nagpur', 'Nashik', 'Aurangabad', 'Amravati', 'Yavatmal'],
    'Punjab':       ['Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala', 'Bathinda'],
    'Uttar Pradesh':['Lucknow', 'Kanpur', 'Varanasi', 'Agra', 'Meerut', 'Gorakhpur'],
    'Madhya Pradesh':['Bhopal', 'Indore', 'Gwalior', 'Jabalpur', 'Rewa'],
    'Rajasthan':    ['Jaipur', 'Jodhpur', 'Udaipur', 'Bikaner', 'Kota'],
    'Gujarat':      ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar'],
    'Andhra Pradesh':['Visakhapatnam', 'Vijayawada', 'Guntur', 'Kurnool', 'Tirupati'],
    'Karnataka':    ['Bengaluru', 'Mysuru', 'Hubli', 'Dharwad', 'Belagavi'],
  };
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
