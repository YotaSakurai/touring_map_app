import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// ユーザーモデル
@JsonSerializable()
class User {
  final String id;
  final String handle;
  final String? displayName;
  final String? iconUrl;
  final String privacyLevel;
  final Map<String, dynamic>? homeGeom;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.handle,
    this.displayName,
    this.iconUrl,
    this.privacyLevel = 'standard',
    this.homeGeom,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// プライバシーレベルの定数
  static const String privacyStrict = 'strict';
  static const String privacyStandard = 'standard';
  static const String privacyOpen = 'open';
}
