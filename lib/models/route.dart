import 'package:json_annotation/json_annotation.dart';

part 'route.g.dart';

/// ルートモデル
@JsonSerializable()
class TouringRoute {
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

  const TouringRoute({
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

  factory TouringRoute.fromJson(Map<String, dynamic> json) => _$TouringRouteFromJson(json);
  Map<String, dynamic> toJson() => _$TouringRouteToJson(this);

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

/// 可視性の定数
class RouteVisibility {
  static const String public = 'public';
  static const String unlisted = 'unlisted';
  static const String private = 'private';
}

/// タグの定数
class RouteTags {
  static const String night = 'night';
  static const String onsen = 'onsen';
  static const String parking2w = 'parking2w';
  static const String riderWelcome = 'rider_welcome';
  static const String scenic = 'scenic';
  static const String food = 'food';
}
