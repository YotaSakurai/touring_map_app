import 'package:json_annotation/json_annotation.dart';

part 'route.g.dart';

/// ルートモデル
@JsonSerializable()
class Route {
  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final Map<String, dynamic> geom; // GeoJSON MultiLineString
  final int? distanceM;
  final int? elevGainM;
  final List<String> tags;
  final String visibility;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Route({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description,
    required this.geom,
    this.distanceM,
    this.elevGainM,
    this.tags = const [],
    this.visibility = 'private',
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Route.fromJson(Map<String, dynamic> json) => _$RouteFromJson(json);
  Map<String, dynamic> toJson() => _$RouteToJson(this);

  /// 可視性の定数
  static const String visibilityPublic = 'public';
  static const String visibilityUnlisted = 'unlisted';
  static const String visibilityPrivate = 'private';

  /// タグの定数
  static const String tagNight = 'night';
  static const String tagOnsen = 'onsen';
  static const String tagParking2w = 'parking2w';
  static const String tagRiderWelcome = 'rider_welcome';
  static const String tagScenic = 'scenic';
  static const String tagFood = 'food';
}
