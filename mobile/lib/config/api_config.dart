class ApiConfig {
  // Base URLs
  static const String baseUrl = 'https://rtmadmin.e-clicks.net/api';
  static const String socketUrl = 'https://rtmadmin.e-clicks.net';

  // API Endpoints
  static const String authBase = '$baseUrl/auth';
  static const String matchBase = '$baseUrl/matches';
  static const String messageBase = '$baseUrl/messages';
  static const String paymentBase = '$baseUrl/payments';

  // Auth Endpoints
  static const String login = '$authBase/login';
  static const String register = '$authBase/register';
  static const String sendOtp = '$authBase/send-otp';
  static const String verifyOtp = '$authBase/verify-otp';
  static const String refreshToken = '$authBase/refresh-token';
  static const String logout = '$authBase/logout';
  static const String forgotPassword = '$authBase/forgot-password';
  static const String resetPassword = '$authBase/reset-password';
  static const String checkPasswordStrength = '$authBase/check-password-strength';
  static const String checkExistence = '$authBase/check-existence';

  // Profile Endpoints
  static const String profileBase = '$baseUrl/profile';
  static const String myProfile = '$profileBase/me';
  static const String updateProfile = '$profileBase/update';
  static const String uploadPhoto = '$profileBase/upload-photo';
  
  // Preferences Endpoints
  static const String preferences = '$matchBase/preferences';

  // Match Endpoints
  static const String exploreMatches = '$matchBase/explore';
  static const String myMatches = matchBase;
  static String likeUser(String userId) => '$matchBase/like/$userId';
  static String passUser(String userId) => '$matchBase/pass/$userId';
  static String unmatch(String matchId) => '$matchBase/unmatch/$matchId';

  // Message Endpoints
  static const String conversations = '$messageBase/conversations';
  static const String sendMessage = messageBase;
  static String getMessages(String conversationId) =>
      '$messageBase/$conversationId';
  static String markAsRead(String messageId) => '$messageBase/$messageId/read';

  // Payment Endpoints
  static const String initializePayment = '$paymentBase/initialize';
  static const String verifyPayment = '$paymentBase/verify';
  static const String transactions = '$paymentBase/transactions';

  // Health Check
  static const String health = '$baseUrl/health';

  // Timeout settings
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
