import 'package:json_annotation/json_annotation.dart';

part 'waypoint.g.dart';

/// ウェイポイントモデル
@JsonSerializable()
class Waypoint {
  final String id;
  final String routeId;
  final int seq;
  final String? name;
  final String? desc;
  final Map<String, dynamic> geom; // GeoJSON Point

  const Waypoint({
    required this.id,
    required this.routeId,
    required this.seq,
    this.name,
    this.desc,
    required this.geom,
  });

  factory Waypoint.fromJson(Map<String, dynamic> json) => _$WaypointFromJson(json);
  Map<String, dynamic> toJson() => _$WaypointToJson(this);
}
