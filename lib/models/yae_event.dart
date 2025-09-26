import 'package:json_annotation/json_annotation.dart';

part 'yae_event.g.dart';

/// ヤエーイベントモデル
@JsonSerializable()
class YaeEvent {
  final String id;
  final String userA;
  final String userB;
  final Map<String, dynamic> geom; // GeoJSON Point
  final DateTime happenedAt;
  final int confidence;
  final String? hashedFromIp;
  final DateTime createdAt;

  const YaeEvent({
    required this.id,
    required this.userA,
    required this.userB,
    required this.geom,
    required this.happenedAt,
    required this.confidence,
    this.hashedFromIp,
    required this.createdAt,
  });

  factory YaeEvent.fromJson(Map<String, dynamic> json) => _$YaeEventFromJson(json);
  Map<String, dynamic> toJson() => _$YaeEventToJson(this);

  /// 信頼度の定数
  static const int confidenceLow = 30;
  static const int confidenceMedium = 60;
  static const int confidenceHigh = 90;
}
