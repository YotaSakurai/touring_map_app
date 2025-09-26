// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waypoint.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Waypoint _$WaypointFromJson(Map<String, dynamic> json) => Waypoint(
      id: json['id'] as String,
      routeId: json['routeId'] as String,
      seq: (json['seq'] as num).toInt(),
      name: json['name'] as String?,
      desc: json['desc'] as String?,
      geom: json['geom'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$WaypointToJson(Waypoint instance) => <String, dynamic>{
      'id': instance.id,
      'routeId': instance.routeId,
      'seq': instance.seq,
      'name': instance.name,
      'desc': instance.desc,
      'geom': instance.geom,
    };
