class AppConstants {
  static String get baseUrl => const String.fromEnvironment(
    'BASE_URL',
    defaultValue: "https://dealiobackend.vercel.app/api",
    // defaultValue: "http://localhost:5000/api"
  ).trim();
}
