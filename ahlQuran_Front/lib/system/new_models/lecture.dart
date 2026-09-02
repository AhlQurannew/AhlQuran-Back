import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class Lecture implements Model {
  dynamic lectureId;
  dynamic teamAccomplishmentId;
  dynamic lectureNameAr = '';
  dynamic lectureNameEn = '';
  dynamic shownOnWebsite;
  dynamic circleType = '';
  dynamic category = '';

  Lecture({
    this.lectureId,
    this.teamAccomplishmentId,
    this.lectureNameAr,
    this.lectureNameEn,
    this.shownOnWebsite,
    this.circleType,
    this.category,
  });

  factory Lecture.fromJson(Map<String, dynamic> json) => Lecture(
        lectureId: json['lectureId'] ?? json['lecture_id'],
        teamAccomplishmentId:
            json['teamAccomplishmentId'] ?? json['team_accomplishment_id'],
        lectureNameAr: json['lectureNameAr'] ?? json['lecture_name_ar'],
        lectureNameEn: json['lectureNameEn'] ?? json['lecture_name_en'],
        shownOnWebsite:
            (json['shownOnWebsite'] ?? json['shown_on_website']) == 1 ||
                (json['shownOnWebsite'] ?? json['shown_on_website']) == true,
        circleType: json['circleType'] ?? json['circle_type'],
        category: json['category'] ?? '',
      );

  @override
  Map<String, dynamic> toJson() => {
        'lecture_id': lectureId,
        'team_accomplishment_id': teamAccomplishmentId,
        'lecture_name_ar': lectureNameAr,
        'lecture_name_en': lectureNameEn,
        'shown_on_website': shownOnWebsite ? 1 : 0,
        'circle_type': circleType,
        'category': category,
      };

  @override
  String toString() {
    return '[ $lectureId ] - $lectureNameEn - $lectureNameAr';
  }

  @override
  bool get isComplete =>
      lectureId != null &&
      teamAccomplishmentId != null &&
      (lectureNameAr != null && lectureNameAr.toString().isNotEmpty) &&
      (lectureNameEn != null && lectureNameEn.toString().isNotEmpty) &&
      shownOnWebsite != null &&
      (circleType != null && circleType.toString().isNotEmpty);
}
