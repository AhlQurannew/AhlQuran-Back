import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/reports/report2_model.dart';

FullAttendanceReport getFullAttendanceReport() {
  return report;
}

final report = FullAttendanceReport(
  reportTitle: 'تقرير الحضور والغياب',
  details: ReportDetails(
    schoolName: "مدرسة النور",
    teacherName: "الأستاذ أحمد",
    lectureName: "الرياضيات - الجبر",
    hijriDate: "1446-01-10",
    gregorianDate: "2025-06-04",
    reportType: "تقرير يومي",
  ),
  students: [
    AttendanceStudent(
      name: 'علي حسن',
      studentId: '001',
      presentCount: 18,
      lateCount: 2,
      absentCount: 1,
      excusedAbsentCount: 0,
    ),
    AttendanceStudent(
      name: 'سارة محمود',
      studentId: '002',
      presentCount: 20,
      lateCount: 0,
      absentCount: 0,
      excusedAbsentCount: 1,
    ),
    AttendanceStudent(
      name: 'عمر خالد',
      studentId: '003',
      presentCount: 15,
      lateCount: 3,
      absentCount: 2,
      excusedAbsentCount: 1,
    ),
  ],
);
