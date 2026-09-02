import 'package:get/get.dart';

// Import bindings
import 'package:the_doctarine_of_the_ppl_of_the_quran/bindings/copy.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/bindings/management_binding.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/bindings/acheivement.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/bindings/student_management_binding.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/bindings/guardian_management_binding.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/bindings/lecture_management_binding.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/bindings/teacher_management_binding.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/bindings/supervisor_management_binding.dart';
//import 'package:the_doctarine_of_the_ppl_of_the_quran/bindings/starter.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/bindings/charts/stat1_binding.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/bindings/charts/stat2_binding.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/bindings/charts/stat3_binding.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/forms/exam_records_form.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/forms/exam_teachers_from.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/appreciation.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/exam.dart';
//import 'package:the_doctarine_of_the_ppl_of_the_quran/bindings/exam_teacher_binding.dart'; // Assuming this is correct

// Import screens
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/exam_management.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/exams/exam_notes.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/exams/exam_records.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/exams/exam_teachers.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/exams/exam_types.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/web/pages/copy.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/student_managment_new.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/guardian_management_new.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/lecture_management_new.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/teacher_management_new.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/supervisor_management_new.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/achievement_managment.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/login.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/admin_dashboard.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/teacher_dashboard_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/testpage.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/flipcard.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/onboarding.dart';

// Report screens (namespaced)
import '../screens/report1_screen.dart' as report1;
import '../screens/report2_screen.dart' as report2;
import '../screens/report3_screen.dart' as report3;
import '../screens/report4_screen.dart' as report4;

// Stats screens
import 'package:the_doctarine_of_the_ppl_of_the_quran/stats/stat1.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/stats/stat2.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/stats/stat3.dart';

// Utility screens
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/forget_password.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/create_account.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/dashboardScreen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/track_and_memorize_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/track_memorize_students_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/attendance_selection_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/attendance_students_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/teacher_attendance_selection_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/teacher_attendance_list_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/reports_menu_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/charts_menu_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/achievement_stats_selection_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/achievement_stats_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/attendance_stats_selection_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/attendance_stats_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/progress_stats_selection_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/progress_stats_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/lecture_stats_selection_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/lecture_stats_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/daily_achievement_report_selection_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/daily_achievement_report_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/attendance_report_selection_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/attendance_report_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/student_detail_report_selection_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/student_detail_report_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/lecture_detail_report_selection_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/lecture_detail_report_screen.dart';
// App routes
import 'package:the_doctarine_of_the_ppl_of_the_quran/routes/app_routes.dart';

//web
import 'package:the_doctarine_of_the_ppl_of_the_quran/web/pages/features.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/web/pages/home.dart';

import 'package:the_doctarine_of_the_ppl_of_the_quran/web/pages/pricing.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/president_middleware.dart';

class AppScreens {
  static final routes = [
    GetPage(
      name: Routes.copy,
      page: () => CopyPage(),
      binding: CopyBinding(),
    ),
    GetPage(
      name: Routes.addStudent,
      page: () => const StudentManagementScreen(),
      binding: StudentManagementBinding(),
    ),
    GetPage(
      name: Routes.addGuardian,
      page: () => const GuardianManagementScreen(),
      binding: GuardianManagementBinding(),
    ),
    // Alias for AddGuardian (case-insensitive)
    GetPage(
      name: '/AddGuardian',
      page: () => const GuardianManagementScreen(),
      binding: GuardianManagementBinding(),
    ),
    GetPage(
      name: Routes.addTeacher,
      page: () => const TeacherManagementScreen(),
      binding: TeacherManagementBinding(),
    ),
    GetPage(
      name: Routes.supervisorManagement,
      page: () => const SupervisorManagementScreen(),
      binding: SupervisorManagementBinding(),
      middlewares: [AuthMiddleware(), PresidentMiddleware()],
    ),
    GetPage(
      name: Routes.addLecture,
      page: () => const LectureManagementScreen(),
      binding: LectureManagementBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.addAchievement,
      page: () => AddAcheivement(),
      binding: AcheivementBinding(),
    ),
    GetPage(
      name: Routes.trackAndMemorize,
      page: () => const TrackAndMemorizeScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.trackAndMemorizeStudents,
      page: () => const TrackMemorizeStudentsScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.test,
      page: () => TestPage(),
    ),
    GetPage(
      name: Routes.logIn,
      page: () => LogInPage(),
    ),
    GetPage(
      name: Routes.adminDashboard,
      page: () => const AdminDashboardScreen(),
    ),
    GetPage(
      name: Routes.teacherDashboard,
      page: () => const TeacherDashboardScreen(),
    ),
    GetPage(
      name: Routes.attendance,
      page: () => const AttendanceSelectionScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.attendanceStudents,
      page: () => const AttendanceStudentsScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.teacherAttendance,
      page: () => const TeacherAttendanceSelectionScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.teacherAttendanceList,
      page: () => const TeacherAttendanceListScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.reportsMenu,
      page: () => const ReportsMenuScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.chartsMenu,
      page: () => const ChartsMenuScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.achievementStatsSelection,
      page: () => const AchievementStatsSelectionScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.achievementStats,
      page: () => const AchievementStatsScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.attendanceStatsSelection,
      page: () => const AttendanceStatsSelectionScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.attendanceStats,
      page: () => const AttendanceStatsScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.progressStatsSelection,
      page: () => const ProgressStatsSelectionScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.progressStats,
      page: () => const ProgressStatsScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.lectureStatsSelection,
      page: () => const LectureStatsSelectionScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.lectureStats,
      page: () => const LectureStatsScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.dailyAchievementReportSelection,
      page: () => const DailyAchievementReportSelectionScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.dailyAchievementReport,
      page: () => const DailyAchievementReportScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.attendanceReportSelection,
      page: () => const AttendanceReportSelectionScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.attendanceReport,
      page: () => const AttendanceReportScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.studentDetailReportSelection,
      page: () => const StudentDetailReportSelectionScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.studentDetailReport,
      page: () => const StudentDetailReportScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.lectureDetailReportSelection,
      page: () => const LectureDetailReportSelectionScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.lectureDetailReport,
      page: () => const LectureDetailReportScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.initial,
      page: () => LogInPage(),
    ),

    // Report screens
    GetPage(name: Routes.report1, page: () => report1.Report1Screen()),
    GetPage(name: Routes.report2, page: () => report2.Report2Screen()),
    GetPage(name: Routes.report3, page: () => report3.Report3Screen()),
    GetPage(name: Routes.report4, page: () => report4.Report4Screen()),

    // Utility screens
    GetPage(name: Routes.test, page: () => const TestPage()),
    GetPage(name: Routes.card, page: () => const StudentSelectionPage()),

    // Exam related screens with bindings
    GetPage(
      name: Routes.examPage,
      page: () => ExamPage(),
    ),
    GetPage(
      name: Routes.examTypes,
      page: () => ExamTypes(),
      binding: ManagementBinding<Exam>(fromJson: Exam.fromJson),
    ),
    GetPage(
      name: Routes.examRecords,
      page: () => ExamRecords(),
      binding: ManagementBinding<ExamRecordInfoDialog>(
          fromJson: ExamRecordInfoDialog.fromJson),
    ),
    GetPage(
      name: Routes.examNotes,
      page: () => ExamNotes(),
      binding: ManagementBinding<Appreciation>(fromJson: Appreciation.fromJson),
    ),
    GetPage(
      name: Routes.examTeachers,
      page: () => ExamTeachers(),
      binding: ManagementBinding<ExamTeacherInfoDialog>(
          fromJson: ExamTeacherInfoDialog.fromJson),
    ),

    /*GetPage(
      name: Routes.financialManagement,
      page: () => ,
      
    ),*/

    // Stats screens
    GetPage(
      name: Routes.stat1,
      page: () => StudentProgressChartScreen(),
      binding: Stat1Binding(),
    ),
    GetPage(
      name: Routes.stat2,
      page: () => AttendanceChartScreen(),
      binding: Stat2Binding(),
    ),
    GetPage(
      name: Routes.stat3,
      page: () => PerformanceChartScreen(),
      binding: Stat3Binding(),
    ),

    // User account related
    GetPage(
      name: Routes.createAccount,
      page: () => CreateAccountScreen(),
    ),
    GetPage(
      name: Routes.forgetPassword,
      page: () => ForgetPasswordScreen(),
    ),
    GetPage(
      name: Routes.onboarding,
      page: () => OnboardingScreen(),
    ),
    GetPage(
      name: Routes.dashboardPage,
      page: () => DashboardPage(),
    ),

    GetPage(
      name: WebRoutes.home,
      page: () => HomePage(),
    ),
    GetPage(
      name: WebRoutes.pricing,
      page: () => PricingPage(),
    ),
    GetPage(
      name: WebRoutes.features,
      page: () => FeaturesPage(),
    ),
  ];
}
