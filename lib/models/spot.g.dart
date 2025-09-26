// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Spot _$SpotFromJson(Map<String, dynamic> json) => Spot(
      id: json['id'] as String,
      geom: json['geom'] as Map<String, dynamic>,
      name: json['name'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      openHoursJson: json['openHoursJson'] as Map<String, dynamic>?,
      verified: json['verified'] as bool? ?? false,
      createdBy: json['createdBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$SpotToJson(Spot instance) => <String, dynamic>{
      'id': instance.id,
      'geom': instance.geom,
      'name': instance.name,
      'tags': instance.tags,
      'openHoursJson': instance.openHoursJson,
      'verified': instance.verified,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt.toIso8601String(),
    };
