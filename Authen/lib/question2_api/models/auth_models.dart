class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class RegisterRequest {
  final String fullName;
  final String email;
  final String password;

  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'password': password,
      };
}

class AuthResponse {
  final bool success;
  final String message;
  final String? accessToken;
  final String? email;
  final String? fullName;

  AuthResponse({
    required this.success,
    required this.message,
    this.accessToken,
    this.email,
    this.fullName,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      accessToken: json['accessToken'] as String? ?? json['token'] as String?,
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
    );
  }
}
