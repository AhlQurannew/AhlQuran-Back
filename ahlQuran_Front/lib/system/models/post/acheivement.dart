import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

import '../../new_models/achivement_unit/surah_ayah.dart';

class Acheivement implements Model {
  int? lectureId;
  int? studentId;
  String? date;
  List<SurahAyah> hifd = [];
  List<SurahAyah> quickRev = [];
  List<SurahAyah> majorRev = [];
  String? teacherNote;
  String? attendanceStatus;

  Acheivement();

  @override
  bool get isComplete {
    return hifd.isNotEmpty || quickRev.isNotEmpty || majorRev.isNotEmpty;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "lectureId": lectureId,
      "studentId": studentId,
      "date": date,
      "hifd": hifd.map((item) => item.toJson()).toList(),
      "quickRev": quickRev.map((item) => item.toJson()).toList(),
      "majorRev": majorRev.map((item) => item.toJson()).toList(),
      "attendenceStatus": attendanceStatus,
      "teacherNote": teacherNote ?? '',
    };
  }

  factory Acheivement.fromJson(Map<String, dynamic> map) {
    return Acheivement()
      ..lectureId = map['lectureId'] as int?
      ..studentId = map['studentId'] as int?
      ..date = map['date'] as String?
      ..hifd = (map['hifd'] as List<dynamic>? ?? [])
          .map((item) => SurahAyah.fromJson(item as Map<String, dynamic>))
          .toList()
      ..quickRev = (map['quickRev'] as List<dynamic>? ?? [])
          .map((item) => SurahAyah.fromJson(item as Map<String, dynamic>))
          .toList()
      ..majorRev = (map['majorRev'] as List<dynamic>? ?? [])
          .map((item) => SurahAyah.fromJson(item as Map<String, dynamic>))
          .toList()
      ..attendanceStatus = map['attendenceStatus'] as String?
      ..teacherNote = map['teacherNote'] as String?;
  }
}
