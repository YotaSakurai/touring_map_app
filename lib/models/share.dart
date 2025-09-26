import 'package:json_annotation/json_annotation.dart';

part 'share.g.dart';

/// 共有トークンモデル
@JsonSerializable()
class Share {
  final String id;
  final String routeId;
  final String token;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const Share({
    required this.id,
    required this.routeId,
    required this.token,
    this.expiresAt,
    required this.createdAt,
  });

  factory Share.fromJson(Map<String, dynamic> json) => _$ShareFromJson(json);
  Map<String, dynamic> toJson() => _$ShareToJson(this);
}
