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
    return ChapterPlan(
      id: fields[0] as String,
      subjectId: fields[1] as String,
      weeklyChapters: fields[2] as int,
      studyDays: (fields[3] as List).cast<int>(),
      completedKeys: (fields[4] as List?)?.cast<int>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, ChapterPlan obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectId)
      ..writeByte(2)
      ..write(obj.weeklyChapters)
      ..writeByte(3)
      ..write(obj.studyDays)
      ..writeByte(4)
      ..write(obj.completedKeys);
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
