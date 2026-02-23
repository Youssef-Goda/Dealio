class AppConstants {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: "https://dealiobackend.vercel.app/api",
    // defaultValue: "http://localhost:5000/api"
  );
}
