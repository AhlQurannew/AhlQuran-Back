class CurriculumSchedule {
  final TajweedAndRecitationSchedule tajweedAndRecitationSchedule;
  final AccompanyingCurriculum accompanyingCurriculum;

  CurriculumSchedule({
    required this.tajweedAndRecitationSchedule,
    required this.accompanyingCurriculum,
  });

  factory CurriculumSchedule.fromJson(Map<String, dynamic> json) {
    return CurriculumSchedule(
      tajweedAndRecitationSchedule: TajweedAndRecitationSchedule.fromJson(
        json['tajweed_and_recitation_schedule'],
      ),
      accompanyingCurriculum: AccompanyingCurriculum.fromJson(
        json['accompanying_curriculum'],
      ),
    );
  }
}

class TajweedAndRecitationSchedule {
  final String title;
  final List<Lesson> lessons;

  TajweedAndRecitationSchedule({required this.title, required this.lessons});

  factory TajweedAndRecitationSchedule.fromJson(Map<String, dynamic> json) {
    return TajweedAndRecitationSchedule(
      title: json['title'],
      lessons:
          (json['lessons'] as List).map((e) => Lesson.fromJson(e)).toList(),
    );
  }
}

class AccompanyingCurriculum {
  final String title;
  final List<AccompanyingLesson> lessons;

  AccompanyingCurriculum({required this.title, required this.lessons});

  factory AccompanyingCurriculum.fromJson(Map<String, dynamic> json) {
    return AccompanyingCurriculum(
      title: json['title'],
      lessons:
          (json['lessons'] as List)
              .map((e) => AccompanyingLesson.fromJson(e))
              .toList(),
    );
  }
}

class Lesson {
  final int id;
  final String day;
  final String recitationTopic;
  final String tajweedTopic;

  Lesson({
    required this.id,
    required this.day,
    required this.recitationTopic,
    required this.tajweedTopic,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      day: json['day'],
      recitationTopic: json['recitation_topic'],
      tajweedTopic: json['tajweed_topic'],
    );
  }
}

class AccompanyingLesson {
  final int id;
  final String day;
  final String subject;
  final String lessonTitle;

  AccompanyingLesson({
    required this.id,
    required this.day,
    required this.subject,
    required this.lessonTitle,
  });

  factory AccompanyingLesson.fromJson(Map<String, dynamic> json) {
    return AccompanyingLesson(
      id: json['id'],
      day: json['day'],
      subject: json['subject'],
      lessonTitle: json['lesson_title'],
    );
  }
}

class StatItem {
  final String label;
  final dynamic value;

  StatItem({required this.label, required this.value});

  factory StatItem.fromJson(Map<String, dynamic> json) {
    return StatItem(label: json['label'], value: json['value']);
  }

  Map<String, dynamic> toJson() {
    return {'label': label, 'value': value};
  }
}

class FullReport<T> {
  final String reportTitle;
  final ReportDetails reportDetails;
  final T overallSummary;
  final DetailedReport detailedReport;
  final CurriculumSchedule curriculumSchedule;

  FullReport({
    required this.reportTitle,
    required this.reportDetails,
    required this.overallSummary,
    required this.detailedReport,
    required this.curriculumSchedule,
  });

  factory FullReport.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) reportDetailsParser,
  ) {
    return FullReport(
      reportTitle: json['reportTitle'],
      reportDetails: ReportDetails.fromJson(json['reportDetails']),
      overallSummary: reportDetailsParser(
        json['overallSummary'],
      ), // ✅ Use parser
      detailedReport: DetailedReport.fromJson(json['detailedReport']),
      curriculumSchedule: CurriculumSchedule.fromJson(
        json['curriculumSchedule'],
      ),
    );
  }
}

class ReportDetails {
  final String schoolName;
  final String teacherName;
  final String reportPeriod;
  final String distinguishedSchool;
  final String courseName;
  final String type;
  final String schoolValue;
  final String courseValue;
  final String periodHijri;
  final String periodMiladi;

  ReportDetails({
    required this.schoolName,
    required this.teacherName,
    required this.reportPeriod,
    required this.distinguishedSchool,
    required this.courseName,
    required this.type,
    required this.schoolValue,
    required this.courseValue,
    required this.periodHijri,
    required this.periodMiladi,
  });
  factory ReportDetails.fromJson(Map<String, dynamic> json) {
    return ReportDetails(
      schoolName: json['schoolName'],
      teacherName: json['teacherName'],
      reportPeriod: json['reportPeriod'],
      distinguishedSchool: json['distinguishedSchool'],
      courseName: json['courseName'],
      type: json['type'],
      schoolValue: json['schoolValue'],
      courseValue: json['courseValue'],
      periodHijri: json['periodHijri'],
      periodMiladi: json['periodMiladi'],
    );
  }
}

class DetailedReport {
  final DetailedReportHeaders headers;
  final List<DailyData> data;

  DetailedReport({required this.headers, required this.data});
  factory DetailedReport.fromJson(Map<String, dynamic> json) {
    return DetailedReport(
      headers: DetailedReportHeaders.fromJson(json['headers']),
      data: List<DailyData>.from(
        json['data'].map((x) => DailyData.fromJson(x)),
      ),
    );
  }
}

class DetailedReportHeaders {
  final String number;
  final String day;
  final SectionHeaders memorization;
  final SectionHeaders review;
  final SectionHeaders reinforcement;

  DetailedReportHeaders({
    required this.number,
    required this.day,
    required this.memorization,
    required this.review,
    required this.reinforcement,
  });
  factory DetailedReportHeaders.fromJson(Map<String, dynamic> json) {
    return DetailedReportHeaders(
      number: json['number'],
      day: json['day'],
      memorization: SectionHeaders.fromJson(json['memorization']),
      review: SectionHeaders.fromJson(json['review']),
      reinforcement: SectionHeaders.fromJson(json['reinforcement']),
    );
  }
}

class SectionHeaders {
  final String from;
  final String to;
  final String pagesCount;
  final String degree;

  SectionHeaders({
    required this.from,
    required this.to,
    required this.pagesCount,
    required this.degree,
  });
  factory SectionHeaders.fromJson(Map<String, dynamic> json) {
    return SectionHeaders(
      from: json['from'],
      to: json['to'],
      pagesCount: json['pagesCount'],
      degree: json['degree'],
    );
  }
}

class DailyData {
  final int number;
  final String day;
  final DailySectionData? memorization;
  final DailySectionData? review;
  final DailySectionData? reinforcement;

  DailyData({
    required this.number,
    required this.day,
    this.memorization,
    this.review,
    this.reinforcement,
  });
  factory DailyData.fromJson(Map<String, dynamic> json) {
    return DailyData(
      number: json['number'],
      day: json['day'],
      memorization:
          json['memorization'] != null
              ? DailySectionData.fromJson(json['memorization'])
              : null,
      review:
          json['review'] != null
              ? DailySectionData.fromJson(json['review'])
              : null,
      reinforcement:
          json['reinforcement'] != null
              ? DailySectionData.fromJson(json['reinforcement'])
              : null,
    );
  }
}

class DailySectionData {
  final String from;
  final String to;
  final double pagesCount;
  final double degree;

  DailySectionData({
    required this.from,
    required this.to,
    required this.pagesCount,
    required this.degree,
  });
  factory DailySectionData.fromJson(Map<String, dynamic> json) {
    return DailySectionData(
      from: json['from'],
      to: json['to'],
      pagesCount: (json['pagesCount'] as num).toDouble(),
      degree: (json['degree'] as num).toDouble(),
    );
  }
}

class HeaderInfo {
  final String schoolName;
  final String teacherName;
  final String lectureName;
  final String reportPeriodHijri;
  final String reportPeriodGregorian;
  final String categoryName;

  HeaderInfo({
    required this.schoolName,
    required this.teacherName,
    required this.lectureName,
    required this.reportPeriodHijri,
    required this.reportPeriodGregorian,
    required this.categoryName,
  });

  factory HeaderInfo.fromJson(Map<String, dynamic> json) {
    return HeaderInfo(
      schoolName: json['school_name'],
      teacherName: json['teacher_name'],
      lectureName: json['lecture_name'],
      reportPeriodHijri: json['report_period_hijri'],
      reportPeriodGregorian: json['report_period_gregorian'],
      categoryName: json['category_name'],
    );
  }
}
