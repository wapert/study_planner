// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

part of 'chapter_plan.dart';

class ChapterPlanAdapter extends TypeAdapter<ChapterPlan> {
  @override
  final int typeId = 5;

  @override
  ChapterPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Defaults for records saved before the period fields existed:
    // treat them as valid for the current week (Mon–Sun).
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final defaultStartKey = ChapterPlan.dateKeyOf(monday);
    final defaultEndKey = ChapterPlan.dateKeyOf(sunday);

    // Oldest format: field[2] was a weekly total count (no field 5).
    final isCountFormat = !fields.containsKey(5);
    if (isCountFormat) {
      final oldTotal = fields[2] as int;
      return ChapterPlan(
        id: fields[0] as String,
        subjectId: fields[1] as String,
        startNum: 1,
        endNum: oldTotal,
        unitIndex: 0,
        studyDays: (fields[3] as List).cast<int>(),
        completedKeys: (fields[4] as List?)?.cast<int>() ?? [],
        startDateKey: defaultStartKey,
        endDateKey: defaultEndKey,
      );
    }

    return ChapterPlan(
      id: fields[0] as String,
      subjectId: fields[1] as String,
      startNum: fields[2] as int,
      studyDays: (fields[3] as List).cast<int>(),
      completedKeys: (fields[4] as List?)?.cast<int>() ?? [],
      endNum: fields[5] as int,
      unitIndex: fields[6] as int? ?? 0,
      startDateKey: fields[7] as int? ?? defaultStartKey,
      endDateKey: fields[8] as int? ?? defaultEndKey,
    );
  }

  @override
  void write(BinaryWriter writer, ChapterPlan obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectId)
      ..writeByte(2)
      ..write(obj.startNum)
      ..writeByte(3)
      ..write(obj.studyDays)
      ..writeByte(4)
      ..write(obj.completedKeys)
      ..writeByte(5)
      ..write(obj.endNum)
      ..writeByte(6)
      ..write(obj.unitIndex)
      ..writeByte(7)
      ..write(obj.startDateKey)
      ..writeByte(8)
      ..write(obj.endDateKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
