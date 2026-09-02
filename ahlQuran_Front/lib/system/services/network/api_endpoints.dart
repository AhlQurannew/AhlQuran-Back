import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API Configuration
class ApiConfig {
  static const String _fallbackIp = 'localhost';
  static const String _fallbackPort = '8000';
  static const String _fallbackApiPath = 'api/v1';
  static const bool _fallbackUseHttps = false;

  static String _trimSlashes(String value) =>
      value.replaceAll(RegExp(r'^/+|/+$'), '');

  static String _buildBaseFromHost({
    required String ip,
    required String port,
    required String apiPath,
    required bool useHttps,
  }) {
    final protocol = useHttps ? 'https' : 'http';
    final defaultPort = useHttps ? '443' : '80';
    final normalizedPath = _trimSlashes(apiPath);
    final pathSuffix = normalizedPath.isEmpty ? '' : '/$normalizedPath';

    if (port == defaultPort || port.isEmpty) {
      return '$protocol://$ip$pathSuffix';
    }

    return '$protocol://$ip:$port$pathSuffix';
  }

  static String _buildBaseFromEnv({
    required String baseUrl,
    required String apiVersion,
  }) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedVersion = _trimSlashes(apiVersion);

    if (normalizedVersion.isEmpty ||
        normalizedBase.endsWith('/$normalizedVersion')) {
      return normalizedBase;
    }

    return '$normalizedBase/$normalizedVersion';
  }

  static String get baseUrl {
    final envBaseUrl = dotenv.env['API_BASE_URL']?.trim() ?? '';
    final envApiVersion = dotenv.env['API_VERSION']?.trim() ?? '';

    if (envBaseUrl.isNotEmpty) {
      return _buildBaseFromEnv(baseUrl: envBaseUrl, apiVersion: envApiVersion);
    }

    return _buildBaseFromHost(
      ip: _fallbackIp,
      port: _fallbackPort,
      apiPath: _fallbackApiPath,
      useHttps: _fallbackUseHttps,
    );
  }
}

/// API Endpoints
/// All API endpoints are built using the base URL from ApiConfig
class ApiEndpoints {
  static String get baseUrl => ApiConfig.baseUrl;

  // AccountInfo endpoints
  static final String getAccountInfos = '$baseUrl/accountinfos';
  static String getAccountInfoById(int id) => '$baseUrl/accountinfos/$id';
  static final String login = '$baseUrl/auth/login';
  static final String signup = '$baseUrl/auth/signup';
  static final String logout = '$baseUrl/auth/logout';
  static final String presidentRegister = '$baseUrl/auth/president/register';
  static final String presidentLogin = '$baseUrl/auth/president/login';
  static final String supervisorLogin = '$baseUrl/auth/supervisor/login';
  static final String getCurrentUser = '$baseUrl/auth/me';

  // Appreciation endpoints
  static final String getAppreciations = '$baseUrl/appreciations';
  static String getAppreciationById(int id) => '$baseUrl/appreciations/$id';

  // ContactInfo endpoints
  static final String getContactInfos = '$baseUrl/contactinfos';
  static String getContactInfoById(int id) => '$baseUrl/contactinfos/$id';

  // Exam endpoints
  static final String getExams = '$baseUrl/exams';
  static String getExamById(int id) => '$baseUrl/exams/$id';

  // ExamLevel endpoints
  static final String getExamLevels = '$baseUrl/examlevels';
  static String getExamLevelById(int id) => '$baseUrl/examlevels/$id';

  // ExamStudent endpoints
  static final String getExamStudents = '$baseUrl/examstudents';
  static String getExamStudentById(int examId, int studentId) =>
      '$baseUrl/examstudents/exams/$examId/students/$studentId';

  // ExamTeacher endpoints
  static final String getExamTeachers = '$baseUrl/examteachers';
  static String getExamTeacherById(int examId, int teacherId) =>
      '$baseUrl/examteachers/exams/$examId/teachers/$teacherId';

  static String deleteExamTeacherByTeacherId(int teacherId) =>
      '$baseUrl/examteachers/exams/teachers/$teacherId';

  // FormalEducationInfo endpoints
  static final String getFormalEducationInfos = '$baseUrl/formaleducationinfos';
  static String getFormalEducationInfoById(int id) =>
      '$baseUrl/formaleducationinfos/$id';

  // GoldenRecord endpoints
  static final String getGoldenRecords = '$baseUrl/goldenrecords';
  static String getGoldenRecordById(int id) => '$baseUrl/goldenrecords/$id';

  // Guardian endpoints
  static final String getGuardians = '$baseUrl/guardians';
  static final String getSpecialGuardians = '$baseUrl/special/guardians';
  static String getSpecialGuardiansById(int id) =>
      '$baseUrl/special/guardians/$id';
  static String getGuardianById(int id) => '$baseUrl/guardians/$id';

  // LectureContent endpoints
  static final String getLectureContents = '$baseUrl/lecturecontents';
  static String getLectureContentById(int id) => '$baseUrl/lecturecontents/$id';

  // Lecture endpoints
  static final String getLectures = '$baseUrl/lectures';
  static final String getSpecialLectures = '$baseUrl/lectures/special/lectures';
  static String getLectureById(int id) =>
      '$baseUrl/lectures/special/lectures/$id';
  static String updateLecture(int id) =>
      '$baseUrl/lectures/special/lectures/$id';
  static String deleteLecture(int id) => '$baseUrl/lectures/$id';

  // LectureStudent endpoints
  static final String getLectureStudents = '$baseUrl/lecturestudents';
  static String getLectureStudentById(int lectureId, int studentId) =>
      '$baseUrl/lecturestudents/lectures/$lectureId/students/$studentId';

  // LectureTeacher endpoints
  static final String getLectureTeachers = '$baseUrl/lectureteachers';
  static String getLectureTeacherById(int lectureId, int teacherId) =>
      '$baseUrl/lectureteachers/lectures/$lectureId/teachers/$teacherId';

  // MedicalInfo endpoints
  static final String getMedicalInfos = '$baseUrl/medicalinfos';
  static String getMedicalInfoById(int id) => '$baseUrl/medicalinfos/$id';

  // PersonalInfo endpoints
  static final String getPersonalInfos = '$baseUrl/personalinfos';
  static String getPersonalInfoById(int id) => '$baseUrl/personalinfos/$id';

  // RequestCopy endpoints
  static final String getRequestCopys = '$baseUrl/requestcopys';
  static String getRequestCopyById(int id) => '$baseUrl/requestcopys/$id';

  // Student endpoints
  static final String getStudents = '$baseUrl/students/';
  static String getStudentById(int id) => '$baseUrl/students/$id';

  // SubscriptionInfo endpoints
  static final String getSubscriptionInfos = '$baseUrl/subscriptioninfos';
  static String getSubscriptionInfoById(int id) =>
      '$baseUrl/subscriptioninfos/$id';

  // Supervisor endpoints
  static final String getSupervisors = '$baseUrl/supervisor';
  static String getSupervisorById(int id) => '$baseUrl/supervisor/$id';

  // Teacher endpoints
  static final String getTeachers = '$baseUrl/teacher/';
  static String getTeacherById(int id) => '$baseUrl/teacher/$id';

  // Teacher-specific student access (read-only)
  static final String getMyStudents = '$baseUrl/teacher/my-students';
  static String getMyStudentById(int id) => '$baseUrl/teacher/my-students/$id';
  static final String getMyLectures = '$baseUrl/teacher/my-lectures';

  // Teacher-specific student attendance endpoints
  static String createMyStudentAttendance(int studentId) =>
      '$baseUrl/teacher/my-students/$studentId/attendance';
  static String getMyStudentAttendance(int studentId) =>
      '$baseUrl/teacher/my-students/$studentId/attendance';
  static String updateMyStudentAttendance(int studentId, int attendanceId) =>
      '$baseUrl/teacher/my-students/$studentId/attendance/$attendanceId';
  static String deleteMyStudentAttendance(int studentId, int attendanceId) =>
      '$baseUrl/teacher/my-students/$studentId/attendance/$attendanceId';

  // Teacher-specific student achievement endpoints
  static String createMyStudentAchievement(int studentId) =>
      '$baseUrl/teacher/my-students/$studentId/achievements';
  static String getMyStudentAchievements(int studentId) =>
      '$baseUrl/teacher/my-students/$studentId/achievements';
  static String updateMyStudentAchievement(int studentId, int achievementId) =>
      '$baseUrl/teacher/my-students/$studentId/achievements/$achievementId';
  static String deleteMyStudentAchievement(int studentId, int achievementId) =>
      '$baseUrl/teacher/my-students/$studentId/achievements/$achievementId';

  // Message endpoints
  static final String getMessages = '$baseUrl/messages/';
  static final String getRecentMessages = '$baseUrl/messages/recent';
  static final String createMessage = '$baseUrl/messages/';
  static String deleteMessage(int id) => '$baseUrl/messages/$id';

  // TeamAccomplishment endpoints
  static final String getTeamAccomplishments = '$baseUrl/teamaccomplishments';
  static String getTeamAccomplishmentById(int id) =>
      '$baseUrl/teamaccomplishments/$id';

  // TeamAccomplishmentStudent endpoints
  static final String getTeamAccomplishmentStudents =
      '$baseUrl/teamaccomplishmentstudents';
  static String getTeamAccomplishmentStudentById(int teamId, int studentId) =>
      '$baseUrl/teamaccomplishmentstudents/teamaccomplishments/$teamId/students/$studentId';

  // WeeklySchedule endpoints
  static final String getWeeklySchedules = '$baseUrl/weeklyschedules';

  static String getLatestAchievements = '$baseUrl/achievements/latest';

  static String getGuardianAccounts = '$baseUrl/guardians';

  static String getLectureIdName =
      '$baseUrl/lectures/ar_name-and-id'; //TODO to be removed

  static String getStudentAchievements = '$baseUrl/achievements';

  //static String getSpecialAchievements = '$baseUrl/special/achievements'; doesnt exist

  static String submitStudentForm = '$baseUrl/students/';
  static String submitLectureForm = '$baseUrl/lectures/special/lectures/submit';
  static String getSpecialLecture(int id) => '$baseUrl/special/lectures/$id';

  static String submitGuardianForm = '$baseUrl/guardians';

  static String getWeeklyScheduleById(int id) => '$baseUrl/weeklyschedules/$id';

  static String getStudentsByLecture(int idLecture) =>
      '$baseUrl/lecturestudents/lectures/$idLecture/students';

  static String getSpecialStudent(int id) => '$baseUrl/students/$id';
  static String updateStudentFull(int id) => '$baseUrl/students/$id/full';

  static String getGuardianByUserName(String? guardianAccountUserName) =>
      '$baseUrl/special/students/$guardianAccountUserName';

  // Special ExamRecords endpoints
  static final String getSpecialExamRecords = '$baseUrl/special/exams-records';
  static final String submitSpecialExamRecord =
      '$baseUrl/special/exams-records/submit';
  static String updateSpecialExamRecord(int id) =>
      '$baseUrl/special/exams-records/$id';

  // Special ExamsTeachers endpoints
  static final String getSpecialExamsTeachers =
      '$baseUrl/special/exams-teachers';
  static final String submitSpecialExamsTeacher =
      '$baseUrl/special/exams-teachers/submit';
  static String updateSpecialExamsTeacher(int id) =>
      '$baseUrl/special/exams-teachers/$id';

  static String uploadImage = '$baseUrl/upload-image';

  static String getSpecialExamRecordsById(int id) =>
      '$baseUrl/special/exams-records/';
}
