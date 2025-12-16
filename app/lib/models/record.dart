import 'package:hive/hive.dart';

part 'record.g.dart';

@HiveType(typeId: 3)
class TemperatureRecord {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String checkpointId;

  @HiveField(2)
  final double temperature;

  @HiveField(3)
  final DateTime recordedAt;

  @HiveField(4)
  final String? recordedBy;

  @HiveField(5)
  final bool isAbnormal;

  @HiveField(6)
  final String? abnormalAction;

  @HiveField(7)
  final String? notes;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final bool? synced; // オフライン対応用

  TemperatureRecord({
    required this.id,
    required this.checkpointId,
    required this.temperature,
    required this.recordedAt,
    this.recordedBy,
    this.isAbnormal = false,
    this.abnormalAction,
    this.notes,
    required this.createdAt,
    this.synced,
  });

  factory TemperatureRecord.fromJson(Map<String, dynamic> json) {
    return TemperatureRecord(
      id: json['id'] as String,
      checkpointId: json['checkpoint_id'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      recordedBy: json['recorded_by'] as String?,
      isAbnormal: (json['is_abnormal'] as int?) == 1,
      abnormalAction: json['abnormal_action'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      synced: json['synced'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'checkpoint_id': checkpointId,
      'temperature': temperature,
      'recorded_at': recordedAt.toIso8601String(),
      'recorded_by': recordedBy,
      'is_abnormal': isAbnormal ? 1 : 0,
      'abnormal_action': abnormalAction,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TemperatureRecord copyWith({
    String? id,
    String? checkpointId,
    double? temperature,
    DateTime? recordedAt,
    String? recordedBy,
    bool? isAbnormal,
    String? abnormalAction,
    String? notes,
    DateTime? createdAt,
    bool? synced,
  }) {
    return TemperatureRecord(
      id: id ?? this.id,
      checkpointId: checkpointId ?? this.checkpointId,
      temperature: temperature ?? this.temperature,
      recordedAt: recordedAt ?? this.recordedAt,
      recordedBy: recordedBy ?? this.recordedBy,
      isAbnormal: isAbnormal ?? this.isAbnormal,
      abnormalAction: abnormalAction ?? this.abnormalAction,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }
}
