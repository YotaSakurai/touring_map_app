// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TouringRoute _$TouringRouteFromJson(Map<String, dynamic> json) => TouringRoute(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      geom: json['geom'] as Map<String, dynamic>,
      distanceM: (json['distanceM'] as num?)?.toInt(),
      elevGainM: (json['elevGainM'] as num?)?.toInt(),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      visibility: json['visibility'] as String? ?? 'private',
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$TouringRouteToJson(TouringRoute instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ownerId': instance.ownerId,
      'title': instance.title,
      'description': instance.description,
      'geom': instance.geom,
      'distanceM': instance.distanceM,
      'elevGainM': instance.elevGainM,
      'tags': instance.tags,
      'visibility': instance.visibility,
      'version': instance.version,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
