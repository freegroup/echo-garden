// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameModel _$GameModelFromJson(Map<String, dynamic> json) => GameModel(
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      seed: (json['seed'] as num?)?.toInt(),
    );

Map<String, dynamic> _$GameModelToJson(GameModel instance) => <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'seed': instance.seed,
    };
