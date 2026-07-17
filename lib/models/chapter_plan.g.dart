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
    // Backward-compat: old format had field[2] = weeklyChapters (total count).
    // New format has field[2] = startNum, field[5] = endNum, field[6] = unitIndex.
    final isOldFormat = !fields.containsKey(5);
    if (isOldFormat) {
      final oldTotal = fields[2] as int;
      return ChapterPlan(
        id: fields[0] as String,
        subjectId: fields[1] as String,
        startNum: 1,
        endNum: oldTotal,
        unitIndex: 0,
        studyDays: (fields[3] as List).cast<int>(),
        completedKeys: (fields[4] as List?)?.cast<int>() ?? [],
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
    );
  }

  @override
  void write(BinaryWriter writer, ChapterPlan obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.unitIndex);
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
