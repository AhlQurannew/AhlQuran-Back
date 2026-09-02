import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class SupervisorAttendance implements Model {
  dynamic supervisorId;
  dynamic attendanceDate;
  dynamic attendanceStatus;
  dynamic checkInTime;
  dynamic checkOutTime;

  SupervisorAttendance({
    this.supervisorId,
    this.attendanceDate,
    this.attendanceStatus,
    this.checkInTime,
    this.checkOutTime,
  });

  factory SupervisorAttendance.fromJson(Map<String, dynamic> json) =>
      SupervisorAttendance(
        supervisorId: json['supervisor_id'],
        attendanceDate: json['attendance_date'],
        attendanceStatus: json['attendance_status'],
        checkInTime: json['check_in_time'],
        checkOutTime: json['check_out_time'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'supervisor_id': supervisorId,
        'attendance_date': attendanceDate,
        'attendance_status': attendanceStatus,
        'check_in_time': checkInTime,
        'check_out_time': checkOutTime,
      };

  @override
  bool get isComplete =>
      supervisorId != null &&
      attendanceDate != null &&
      attendanceStatus != null &&
      checkInTime != null &&
      checkOutTime != null;
}
