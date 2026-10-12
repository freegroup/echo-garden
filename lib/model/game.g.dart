// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameModel _$GameModelFromJson(Map<String, dynamic> json) => GameModel(
      size: const Vector2Converter()
          .fromJson(json['size'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GameModelToJson(GameModel instance) => <String, dynamic>{
      'size': const Vector2Converter().toJson(instance.size),
    };
