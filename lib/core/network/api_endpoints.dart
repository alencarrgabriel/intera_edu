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

  // Grupos por disciplina
  static const String disciplines = '/disciplines';
  static const String groups = '/groups';
  static String group(String id) => '/groups/$id';
  static String groupJoin(String id) => '/groups/$id/join';
  static String groupMembers(String id) => '/groups/$id/members';
  static String groupFeed(String id) => '/groups/$id/feed';

  // Banco de materiais
  static String groupMaterials(String id) => '/groups/$id/materials';
  static String materialDownload(String id) => '/materials/$id/download';
  static String materialRate(String id) => '/materials/$id/rate';
  static String material(String id) => '/materials/$id';

  // Bookmarks
  static const String bookmarks = '/bookmarks';
  static String postBookmark(String id) => '/posts/$id/bookmark';

  // Stories
  static const String stories = '/stories';
  static const String myStories = '/stories/mine';
  static String storyView(String id) => '/stories/$id/view';
  static String story(String id) => '/stories/$id';

  // Tags
  static const String tags = '/tags';
  static const String trendingTags = '/tags/trending';
  static const String myTags = '/tags/mine';
  static String tag(String slug) => '/tags/$slug';
  static String tagPosts(String slug) => '/tags/$slug/posts';
  static String tagFollow(String slug) => '/tags/$slug/follow';

  // Sugestões
  static const String suggestions = '/users/me/suggestions';

  // Mentions
  static String userByHandle(String handle) => '/users/handle/$handle';
}
