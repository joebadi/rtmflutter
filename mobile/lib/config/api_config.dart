class ApiConfig {
  // ---------------------------------------------------------------------------
  // Environment selection
  //
  // Pick an environment at build/run time:
  //   flutter run --dart-define=APP_ENV=dev        # local backend
  //   flutter run --dart-define=APP_ENV=staging
  //   flutter build ... (no flag)                  # prod (default)
  //
  // Or override the URLs directly (wins over APP_ENV):
  //   --dart-define=API_BASE_URL=http://192.168.1.5:4000/api
  //   --dart-define=SOCKET_URL=http://192.168.1.5:4000
  //
  // `dev` defaults to 10.0.2.2 (the Android emulator's alias for the host
  // machine's localhost); override API_BASE_URL for a physical device or iOS.
  // ---------------------------------------------------------------------------
  static const String environment =
      String.fromEnvironment('APP_ENV', defaultValue: 'prod');

  static const String _explicitBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _explicitSocketUrl = String.fromEnvironment('SOCKET_URL');

  static const bool isProduction = environment == 'prod';

  // Per-environment defaults.
  static const String _prodBase = 'https://rtmadmin.e-clicks.net/api';
  static const String _prodSocket = 'https://rtmadmin.e-clicks.net';
  static const String _stagingBase = 'https://staging.rtmadmin.e-clicks.net/api';
  static const String _stagingSocket = 'https://staging.rtmadmin.e-clicks.net';
  static const String _devBase = 'http://10.0.2.2:4000/api';
  static const String _devSocket = 'http://10.0.2.2:4000';

  // Base URLs — const so the endpoint constants below can interpolate them.
  static const String baseUrl = _explicitBaseUrl != ''
      ? _explicitBaseUrl
      : environment == 'dev'
          ? _devBase
          : environment == 'staging'
              ? _stagingBase
              : _prodBase;

  static const String socketUrl = _explicitSocketUrl != ''
      ? _explicitSocketUrl
      : environment == 'dev'
          ? _devSocket
          : environment == 'staging'
              ? _stagingSocket
              : _prodSocket;

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
  static const String deleteAccount = '$authBase/account';
  static const String forgotPassword = '$authBase/forgot-password';

  // Legal documents (privacy_policy | terms_of_use)
  static String legalDocument(String slug) => '$baseUrl/legal/$slug';
  static const String resetPassword = '$authBase/reset-password';
  static const String checkPasswordStrength = '$authBase/check-password-strength';
  static const String checkExistence = '$authBase/check-existence';

  // Profile Endpoints
  static const String profileBase = '$baseUrl/profile';
  static const String myProfile = '$profileBase/me';
  static const String updateProfile = '$profileBase/update';
  static const String uploadPhoto = '$profileBase/upload-photo';
  static const String privacySettings = '$profileBase/privacy-settings';
  
  // Preferences Endpoints
  static const String preferences = '$matchBase/preferences';

  // Match Endpoints
  static const String exploreMatches = '$matchBase/explore';
  static const String myMatches = matchBase;
  static String compatibility(String targetUserId) =>
      '$matchBase/compatibility/$targetUserId';
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
