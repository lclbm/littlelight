//@dart=2.12

import 'package:json_annotation/json_annotation.dart';

part 'game_data.g.dart';

@JsonSerializable()
class ReputationRanks {
  int glory;
  int valor;
  int infamy;
  ReputationRanks({
    required this.glory,
    required this.valor,
    required this.infamy,
  });

  factory ReputationRanks.fromJson(dynamic json) {
    return _$ReputationRanksFromJson(json);
  }

  dynamic toJson() {
    return _$ReputationRanksToJson(this);
  }
}

@JsonSerializable()
class GameData {
  int softCap;
  int powerfulCap;
  int pinnacleCap;
  List<int>? seasonalModSlots;
  List<int>? tabbedPresentationNodes;
  ReputationRanks ranks;

  GameData({
    required this.softCap,
    required this.powerfulCap,
    required this.pinnacleCap,
    this.seasonalModSlots,
    this.tabbedPresentationNodes,
    required this.ranks,
  });

  factory GameData.fromJson(dynamic json) {
    return _$GameDataFromJson(json);
  }

  dynamic toJson() {
    return _$GameDataToJson(this);
  }
}
