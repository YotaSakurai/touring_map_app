// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      handle: json['handle'] as String,
      displayName: json['displayName'] as String?,
      iconUrl: json['iconUrl'] as String?,
      privacyLevel: json['privacyLevel'] as String? ?? 'standard',
      homeGeom: json['homeGeom'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'handle': instance.handle,
      'displayName': instance.displayName,
      'iconUrl': instance.iconUrl,
      'privacyLevel': instance.privacyLevel,
      'homeGeom': instance.homeGeom,
      'createdAt': instance.createdAt.toIso8601String(),
    };
