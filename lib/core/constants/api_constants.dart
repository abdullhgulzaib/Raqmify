class ApiConstants {
  // Production Vercel Live Backend URL
  static const String productionUrl = 'https://expense-tracker-pro-navy.vercel.app';

  // Base URL pointing directly to production Vercel backend
  static String get baseUrl => productionUrl;

  // Auth Endpoints
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String me = '/api/auth/me';

  // Expense Endpoints
  static const String expenses = '/api/expenses';

  // Analytics Endpoints
  static const String analyticsSummary = '/api/analytics/summary';

  // SplitVault Endpoints
  static const String splitVaultSummary = '/api/splitvault/summary';
  static const String groups = '/api/splitvault/groups';
  static const String createGroup = '/api/splitvault/groups';
  static const String joinGroup = '/api/splitvault/groups/join';
  static const String groupExpenses = '/api/splitvault/expenses';

  // Notifications
  static const String notifications = '/api/notifications';
  
  // Cleanup & Retention
  static const String cleanupStatus = '/api/cleanup/status';
}
