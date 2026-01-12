class LoginRequest {
  final String emailOrUsername;
  final String password;

  LoginRequest({required this.emailOrUsername, required this.password});

  Map<String, dynamic> toJson() => {
        'emailOrUsername': emailOrUsername,
        'password': password,
      };
}

class LoginResponse {
  final String token;
  LoginResponse({required this.token});

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      LoginResponse(token: json['token'] as String);
}
