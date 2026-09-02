// Represents a single student's attendance record
class AttendanceStudent {
  final String name;
  final String studentId;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int excusedAbsentCount;

  AttendanceStudent({
    required this.name,
    required this.studentId,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.excusedAbsentCount,
  });
}

// Represents overall report information (metadata)
class ReportDetails {
  final String schoolName;
  final String teacherName;
  final String lectureName;
  final String hijriDate;
  final String gregorianDate;
  final String reportType;

  ReportDetails({
    required this.schoolName,
    required this.teacherName,
    required this.lectureName,
    required this.hijriDate,
    required this.gregorianDate,
    required this.reportType,
  });
}

// Represents the full report combining metadata + list of students
class FullAttendanceReport {
  final String reportTitle;
  final ReportDetails details;
  final List<AttendanceStudent> students;

  FullAttendanceReport({
    required this.reportTitle,
    required this.details,
    required this.students,
  });
}
