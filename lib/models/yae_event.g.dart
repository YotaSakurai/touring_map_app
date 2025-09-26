// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yae_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YaeEvent _$YaeEventFromJson(Map<String, dynamic> json) => YaeEvent(
      id: json['id'] as String,
      userA: json['userA'] as String,
      userB: json['userB'] as String,
      geom: json['geom'] as Map<String, dynamic>,
      happenedAt: DateTime.parse(json['happenedAt'] as String),
      confidence: (json['confidence'] as num).toInt(),
      hashedFromIp: json['hashedFromIp'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$YaeEventToJson(YaeEvent instance) => <String, dynamic>{
      'id': instance.id,
      'userA': instance.userA,
      'userB': instance.userB,
      'geom': instance.geom,
      'happenedAt': instance.happenedAt.toIso8601String(),
      'confidence': instance.confidence,
      'hashedFromIp': instance.hashedFromIp,
      'createdAt': instance.createdAt.toIso8601String(),
    };
