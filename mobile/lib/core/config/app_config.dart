/// App Configuration
class AppConfig {
  static const String appName = 'Expense Control';
  static const String apiBaseUrl = 'https://control-de-gastos-csi.onrender.com/api';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String expensesEndpoint = '/expenses';
  static const String reportsEndpoint = '/reports';
  static const String categoriesEndpoint = '/categories';
  
  // Settings
  static const int maxImageSizeMB = 10;
  static const int requestTimeoutSeconds = 30;
  
  // OCR
  static const double ocrConfidenceThreshold = 0.7;
}
