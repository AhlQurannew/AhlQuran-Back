import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/data/flip_card_data.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/student.dart';
import 'search_field.dart'
    as custom_search; // import the search controller + widget

import 'package:flip_card/flip_card.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/base_layout.dart';

final List<Map<String, dynamic>> studentList = studentData;

// Controller to hold selected student data
class StudentController extends GetxController {
  final student = Rxn<Student>();

  void loadStudentFromJson(Map<String, dynamic> json) {
    student.value = Student.fromJson(json);
  }
}

// The student card (same as before, simplified here for clarity)
class StudentCard extends StatelessWidget {
  final String logoPath;

  const StudentCard({super.key, required this.logoPath});

  @override
  Widget build(BuildContext context) {
    final studentController = Get.find<StudentController>();
    final student = studentController.student.value!;

    final theme = Theme.of(context);

    return Center(
      child: SizedBox(
        width: 600,
        height: 400,
        child: FlipCard(
          direction: FlipDirection.HORIZONTAL,
          front: _buildFrontCard(student, logoPath, theme),
          back: _buildBackCard(student, theme),
        ),
      ),
    );
  }

  Widget _buildFrontCard(Student student, String logoPath, ThemeData theme) {
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header with school name
            _buildHeader(student, theme),
            const SizedBox(height: 16),

            // Student content
            Expanded(
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side: avatar and logo
                    Column(
                      children: [
                        _buildStudentAvatar(),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 80,
                          child: Image.asset(logoPath, fit: BoxFit.contain),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Right side: student info details
                    Expanded(child: _buildStudentInfo(student)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Student student, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          student.formalEducationInfo.schoolName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 2.0),
      ),
      child: ClipOval(
        child: Image.asset('assets/avatar.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildStudentInfo(Student student) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildInfoRow('الاسم الكامل', student.personalInfo.getFullArName()),
        _buildInfoRow('تاريخ الميلاد', student.personalInfo.dateOfBirth),
        _buildInfoRow('زمرة الدم', student.medicalInfo.bloodType),
        _buildInfoRow('المستوى', student.formalEducationInfo.academicLevel),
        _buildInfoRow('السنة الدراسية', 2019.toString()), //TODO
        _buildInfoRow('رقم الهاتف', student.contactInfo.phoneNumber),
        _buildInfoRow('اسم المستخدم', student.accountInfo.username),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label : ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                fontSize: 16,
              ),
            ),
            TextSpan(
              text: value,
              style: Theme.of(Get.context!).textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard(Student student, ThemeData theme) {
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'بطاقة الطالب',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              student.formalEducationInfo.schoolName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'الجهة الخلفية للبطاقة - معلومات إضافية\n'
                'يمكنك هنا إضافة بيانات مثل عنوان السكن، البريد الإلكتروني، أو توقيع الطالب.',
                style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: 16),
            _buildQrCodePlaceholder(),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCodePlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'QR Code',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
    );
  }
}

// Main page widget
class StudentSelectionPage extends StatelessWidget {
  const StudentSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Controller setup
    final StudentController studentController = Get.put(StudentController());
    final List<Student> students = studentList
        .cast<Map<String, dynamic>>()
        .map((json) => Student.fromJson(json))
        .toList();

    final custom_search.SearchController<Student> searchController = Get.put(
      custom_search.SearchController<Student>(
        items: students,
        filter: (student, query) =>
            "${student.personalInfo.getFullArName()} ${student.personalInfo.getFullEnName()}"
                .toLowerCase()
                .contains(query.toLowerCase()),
      ),
    );

    return BaseLayout(
      title: 'البحث عن طالب',
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 LEFT PANEL: Search + Results
            Flexible(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 60,
                    child: custom_search.SearchField<Student>(
                      controller: searchController,
                      hint: 'ابحث عن اسم الطالب',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Obx(() {
                      final filtered = searchController.filteredList;
                      final showResults = searchController.showResults.value;

                      if (!showResults) return const SizedBox();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'لا توجد نتائج',
                            style: theme.textTheme.titleMedium,
                            textDirection: TextDirection.rtl,
                          ),
                        );
                      }

                      return Scrollbar(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final student = filtered[index];
                            return ListTile(
                              title: Text(
                                "${student.personalInfo.getFullArName()} ${student.personalInfo.getFullEnName()}",
                                textDirection: TextDirection.rtl,
                                style: theme.textTheme.titleMedium,
                              ),
                              onTap: () {
                                studentController.student.value = student;

                                searchController.reset();
                              },
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 40),

            // 🪪 RIGHT PANEL: StudentCard
            Expanded(
              flex: 2,
              child: Obx(() {
                final student = studentController.student.value;

                if (student == null) {
                  return Center(
                    child: Text(
                      "الرجاء اختيار طالب لعرض البطاقة",
                      textDirection: TextDirection.rtl,
                      style: theme.textTheme.displayLarge,
                    ),
                  );
                }

                return Align(
                  alignment: Alignment.topCenter,
                  child: StudentCard(logoPath: 'assets/logo.png'),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
