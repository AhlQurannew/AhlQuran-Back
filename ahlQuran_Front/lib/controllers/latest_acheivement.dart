import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/achivement_unit/surah_ayah.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/student_lecture_achievements.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/api_client.dart';

import '/system/services/network/api_endpoints.dart';

class LatestAcheivementModel implements Model {
  int? studentId;
  int? lectureId;
  LatestAcheivementModel({
    this.studentId,
    this.lectureId,
  });

  @override
  bool get isComplete => studentId != null && lectureId != null;
  @override
  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'lecture_id': lectureId,
    };
  }
}

/*
there is diffrend data structures for json 
1- json array of objects = [{key:value}] = list pf maps
2- json object = {key:value} = map
*/
enum AcheivementCategory { hifd, quickRev, majorRev }

class LatestAcheivement extends GetxController {
  SurahAyah? latestehifdList;
  SurahAyah? latestquickRevList;
  SurahAyah? latestmajorRevList;
  final Rx<AcheivementCategory> selectedType = AcheivementCategory.hifd.obs;
  TextEditingController fromSurah = TextEditingController();
  TextEditingController toSurah = TextEditingController();
  TextEditingController fromAyah = TextEditingController();
  TextEditingController toAyah = TextEditingController();
  TextEditingController observation = TextEditingController();
  void updateSelectedType(AcheivementCategory type) {
    selectedType.value = type;
    assignControllerValue(type);
  }

  void assignControllerValue(AcheivementCategory type) {
    switch (type) {
      case AcheivementCategory.hifd:
        if (latestehifdList != null) setControllerValue(latestehifdList!);
        break;
      case AcheivementCategory.quickRev:
        if (latestquickRevList != null) setControllerValue(latestquickRevList!);
        break;
      case AcheivementCategory.majorRev:
        if (latestmajorRevList != null) setControllerValue(latestmajorRevList!);
        break;
    }
  }

  void clearController() {
    fromSurah.clear();
    toSurah.clear();
    fromAyah.clear();
    toAyah.clear();
    observation.clear();
  }

  void setControllerValue(SurahAyah surahAyah) {
    /*
    no ?. for strings 
    because we dont need to convert them 
    and the main purpose of ?. was to check if the value is null or not before conver
    */
    fromSurah.text = surahAyah.fromSurahName ?? '';
    toSurah.text = surahAyah.toSurahName ?? '';
    fromAyah.text = surahAyah.fromAyahNumber?.toString() ?? '';
    toAyah.text = surahAyah.toAyahNumber?.toString() ?? '';
    observation.text = surahAyah.observation ?? '';
  }

  Future<StudentLectureAchievements> getData(
      int studentId, int lectureId) async {
    return await ApiService.fetchObject<StudentLectureAchievements>(
        ApiEndpoints.getLatestAchievements,
        StudentLectureAchievements.fromJson);
  }
}
