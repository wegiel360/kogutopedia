class AppConstants {
  AppConstants._();

  static const String appName = 'Kogutopedia';
  static const String appVersion = '0.0.1-alpha';

  static const String defaultCharacter = 'Tomek';
  static const List<String> predefinedCharacters = [
    'Tomek',
    'Marek',
    'Kasia',
  ];

  static const Duration maxVideoDuration = Duration(seconds: 30);
  static const int maxImageSizeKB = 500;
  static const int imageQuality = 80;

  static const int streakMotivationThreshold = 3;
  static const int paparazziThreshold = 10;
  static const int directorThreshold = 5;
  static const int napMasterThreshold = 20;

  static const List<String> napKeywords = [
    'drzemka', 'spanie', 'sen', 'śpi', 'drzemał', 'drzemała',
    'odpoczynek', 'odpoczywa', 'leniuchuje', 'siedzi cicho',
  ];

  static const List<String> kitchenKeywords = [
    'kuchnia', 'łazienka', 'gotowanie', 'mycie', 'kuchenka',
    'zlew', 'wanna', 'prysznic',
  ];

  static const List<String> dailyChallenges = [
    'Zrób pierwsze zdjęcie Tomka dzisiaj',
    'Nagraj krótki film z Tomkiem',
    'Opisz dzisiejszą przygodę Tomka',
    'Znajdź Tomka w nowym miejscu',
    'Uchwyć Tomka podczas jedzenia',
    'Zrób zdjęcie Marek i Tomka razem',
    'Dokumentuj drzemkę Tomka',
    'Nagraj dźwięk Tomka',
    'Zrób portret Tomka z bliska',
    'Opisz ulubioną zabawkę Tomka',
  ];
}
