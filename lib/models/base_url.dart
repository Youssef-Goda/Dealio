class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL', 
    defaultValue: "https://dealiobackend.vercel.app/api"
  );
}