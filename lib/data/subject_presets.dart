import '../models/subject.dart';
import '../models/user_profile.dart';

class SubjectPreset {
  final String name;
  final int colorValue;
  const SubjectPreset(this.name, this.colorValue);
}

const _juniorPresets = [
  SubjectPreset('國文', 0xFFE53935),
  SubjectPreset('英文', 0xFF1E88E5),
  SubjectPreset('數學', 0xFF43A047),
  SubjectPreset('自然', 0xFF00ACC1),
  SubjectPreset('歷史', 0xFF6D4C41),
  SubjectPreset('地理', 0xFFFF8F00),
  SubjectPreset('公民', 0xFF8E24AA),
];

const _seniorPresets = [
  SubjectPreset('國文', 0xFFE53935),
  SubjectPreset('英文', 0xFF1E88E5),
  SubjectPreset('數學', 0xFF43A047),
  SubjectPreset('物理', 0xFF8E24AA),
  SubjectPreset('化學', 0xFFFF8F00),
  SubjectPreset('生物', 0xFF2E7D32),
  SubjectPreset('地科', 0xFF546E7A),
  SubjectPreset('歷史', 0xFF6D4C41),
  SubjectPreset('地理', 0xFFEF6C00),
  SubjectPreset('選修', 0xFFEC407A),
];

List<SubjectPreset> presetsFor(SchoolLevel level) {
  switch (level) {
    case SchoolLevel.junior:
      return _juniorPresets;
    case SchoolLevel.senior:
      return _seniorPresets;
    case SchoolLevel.custom:
      return [];
  }
}

List<Subject> buildSubjects(SchoolLevel level, String Function() idGen) {
  return presetsFor(level).map((p) => Subject(
        id: idGen(),
        name: p.name,
        colorValue: p.colorValue,
        weeklyGoalMinutes: 120,
      )).toList();
}
