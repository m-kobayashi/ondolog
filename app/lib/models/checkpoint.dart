import 'package:hive/hive.dart';

part 'checkpoint.g.dart';

@HiveType(typeId: 2)
class Checkpoint {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String locationId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String checkpointType;

  @HiveField(4)
  final double? minTemp;

  @HiveField(5)
  final double? maxTemp;

  @HiveField(6)
  final int sortOrder;

  @HiveField(7)
  final bool isActive;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  Checkpoint({
    required this.id,
    required this.locationId,
    required this.name,
    required this.checkpointType,
    this.minTemp,
    this.maxTemp,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Checkpoint.fromJson(Map<String, dynamic> json) {
    return Checkpoint(
      id: json['id'] as String,
      locationId: json['location_id'] as String,
      name: json['name'] as String,
      checkpointType: json['checkpoint_type'] as String,
      minTemp: (json['min_temp'] as num?)?.toDouble(),
      maxTemp: (json['max_temp'] as num?)?.toDouble(),
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: (json['is_active'] as int?) == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location_id': locationId,
      'name': name,
      'checkpoint_type': checkpointType,
      'min_temp': minTemp,
      'max_temp': maxTemp,
      'sort_order': sortOrder,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool isTemperatureAbnormal(double temperature) {
    if (minTemp != null && temperature < minTemp!) return true;
    if (maxTemp != null && temperature > maxTemp!) return true;
    return false;
  }

  Checkpoint copyWith({
    String? id,
    String? locationId,
    String? name,
    String? checkpointType,
    double? minTemp,
    double? maxTemp,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Checkpoint(
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      name: name ?? this.name,
      checkpointType: checkpointType ?? this.checkpointType,
      minTemp: minTemp ?? this.minTemp,
      maxTemp: maxTemp ?? this.maxTemp,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
