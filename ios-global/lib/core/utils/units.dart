class Units {
  static bool useCelsius = true;
  static bool useKg = true;

  static String temp(double celsius) =>
      useCelsius ? '${celsius.round()}°C' : '${(celsius * 9 / 5 + 32).round()}°F';

  static String weight(double kg) =>
      useKg ? '${kg.round()}kg' : '${(kg * 2.205).round()}lb';

  static Future<void> loadPrefs() async {
    // SharedPreferences loading handled by caller
  }
}
