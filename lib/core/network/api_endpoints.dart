class ApiEndpoints {
  // Auth
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String completeRegistration = '/auth/complete-registration';
  static const String login = '/auth/login';
  static const String google = '/auth/google';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Profile
  static const String myProfile = '/users/me';
  static const String myDataExport = '/users/me/data-export';
  static const String searchUsers = '/users/search';
  static String userProfile(String id) => '/users/$id';

  // RF-15 — Blocks
  static const String myBlocks = '/users/me/blocks';
  static String blockUser(String userId) => '/users/me/blocks/$userId';

  // RF-39 / RF-40 — Reports
  static const String reports = '/reports';

  // RF-35 — Notifications
  static const String notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';

  // Connections
  static const String connections = '/connections';
  static String connection(String id) => '/connections/$id';

  // Feed
  static const String posts = '/posts';
  static String post(String id) => '/posts/$id';
  static String postReactions(String id) => '/posts/$id/reactions';
  static String postComments(String id) => '/posts/$id/comments';

  // Messaging
  static const String chats = '/chats';
  static String chat(String id) => '/chats/$id';
  static String chatMessages(String id) => '/chats/$id/messages';

  // Skills
  static const String skills = '/skills';
  static const String skillsSearch = '/skills/search';
}
