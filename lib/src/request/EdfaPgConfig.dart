import 'dart:convert';

enum EdfaPgEnvironment { TEST, LIVE }

class EdfaPgConfig {
  final EdfaPgEnvironment environment;
  final String merchantKey;

  EdfaPgConfig({
    required this.environment,
    required this.merchantKey,
  });

  Map<String, dynamic> toJson() {
    return {
      "environment": environment.toString().split('.').last,
      "merchantKey": merchantKey,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
