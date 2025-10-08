import 'dart:convert';

class EdfaPgRecurringOptions {
  String? firstTransactionId;
  String? token;

  EdfaPgRecurringOptions({
    this.firstTransactionId,
    this.token,
  });

  EdfaPgRecurringOptions.fromJson(dynamic json) {
    firstTransactionId = json['firstTransactionId'];
    token = json['token'];
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (firstTransactionId != null) map['firstTransactionId'] = firstTransactionId;
    if (token != null) map['token'] = token;
    return map;
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
