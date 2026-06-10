import 'package:hive/hive.dart';

part 'user_profile.g.dart';

enum SchoolLevel { junior, senior, custom }

extension SchoolLevelLabel on SchoolLevel {
  String get label {
    switch (this) {
      case SchoolLevel.junior: return '國中';
      case SchoolLevel.senior: return '高中';
      case SchoolLevel.custom: return '自訂';
    }
  }

  String get emoji {
    switch (this) {
      case SchoolLevel.junior: return '🏫';
      case SchoolLevel.senior: return '🎓';
      case SchoolLevel.custom: return '✏️';
    }
  }
}

@HiveType(typeId: 4)
class UserProfile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int schoolLevelIndex;

  UserProfile({
    required this.id,
    required this.name,
    required this.schoolLevelIndex,
  });

  SchoolLevel get schoolLevel => SchoolLevel.values[schoolLevelIndex];
}
