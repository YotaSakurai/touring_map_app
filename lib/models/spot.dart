import 'package:json_annotation/json_annotation.dart';

part 'spot.g.dart';

/// スポットモデル
@JsonSerializable()
class Spot {
  final String id;
  final Map<String, dynamic> geom; // GeoJSON Point
  final String name;
  final List<String> tags;
  final Map<String, dynamic>? openHoursJson;
  final bool verified;
  final String? createdBy;
  final DateTime createdAt;

  const Spot({
    required this.id,
    required this.geom,
    required this.name,
    required this.tags,
    this.openHoursJson,
    this.verified = false,
    this.createdBy,
    required this.createdAt,
  });

  factory Spot.fromJson(Map<String, dynamic> json) => _$SpotFromJson(json);
  Map<String, dynamic> toJson() => _$SpotToJson(this);

  /// スポットタグの定数
  static const String tagParking2w = 'parking2w';
  static const String tagNight = 'night';
  static const String tagOnsen = 'onsen';
  static const String tagRiderWelcome = 'rider_welcome';
  static const String tagFood = 'food';
  static const String tagGas = 'gas';
  static const String tagRepair = 'repair';
  static const String tagView = 'view';
}
