class AppConfig {
  static const baseUrl =
      'https://pubs-api-prod-ckevc6h9cqfwbphs.australiacentral-01.azurewebsites.net';

  // Keep consistent casing
  static const loginPath = '/api/auth/login';
  static const refreshPath = '/api/auth/refresh';
  static const logoutPath = '/api/auth/logout'; // optional if you use it later
  static const alertHealthInspectionPath = '/v1/alerts/health-inspection';

}
