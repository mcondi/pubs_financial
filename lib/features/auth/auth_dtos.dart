class LoginRequest {
  final String emailOrUsername;
  final String password;

  LoginRequest({
    required this.emailOrUsername,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'emailOrUsername': emailOrUsername,
        'password': password,
      };
}

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;
  final String? email;
  final String? username;
  final String? role;
  final bool isSandbox;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
    this.email,
    this.username,
    this.role,
    required this.isSandbox,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      expiresInSeconds: json['expiresInSeconds'],
      email: json['email'],
      username: json['username'],
      role: json['role'],
      isSandbox: json['isSandbox'] ?? false,
    );
  }
}

class RefreshRequest {
  final String refreshToken;
  RefreshRequest(this.refreshToken);

  Map<String, dynamic> toJson() => {
        'refreshToken': refreshToken,
      };
}

class RefreshResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;

  RefreshResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
  });

  factory RefreshResponse.fromJson(Map<String, dynamic> json) {
    return RefreshResponse(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      expiresInSeconds: json['expiresInSeconds'],
    );
  }
}
