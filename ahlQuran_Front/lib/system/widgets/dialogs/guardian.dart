// Imports
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_edit_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/dialog.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/api_client.dart';
import '../drop_down.dart';
import '../../new_models/forms/guardian_form.dart';
import '../../utils/const/guardian.dart';
import '../../../controllers/generate.dart';
import '../../../controllers/validator.dart';
import '../custom_container.dart';
import '../input_field.dart';
import '../../../system/services/network/api_endpoints.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/helpers/date_picker.dart';

class GuardianDialog extends GlobalDialog {
  const GuardianDialog({
    super.key,
    super.dialogHeader = "إضافة ولي",
    super.numberInputs = 10,
  });

  @override
  State<GlobalDialog> createState() => _GuardianDialogState();
}

class _GuardianDialogState<
        GEC extends GenericEditController<GuardianInfoDialog>>
    extends DialogState<GEC> {
  late Generate generate;
  var guardianInfo = GuardianInfoDialog();
  final RxList<Map<String, dynamic>> students = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingStudents = true.obs;
  int? selectedStudentId;

  @override
  void initState() {
    super.initState();
    generate = Get.isRegistered<Generate>()
        ? Get.find<Generate>()
        : Get.put(Generate());
    formController.controllers[9].text = generate.generatePassword();

    if (editController?.model.value != null) {
      // In edit mode, use the original reference - no deep copy needed
      guardianInfo = editController!.model.value!;
      selectedStudentId = guardianInfo.studentId;
    } else {
      guardianInfo.accountInfo.accountType = "guardian";
    }

    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      isLoadingStudents.value = true;

      // Use ApiService which handles token refresh automatically
      final data = await ApiService.fetchObject<Map<String, dynamic>>(
        ApiEndpoints.getStudents,
        (json) => json,
      );

      final List<dynamic> studentsData = data['students'] ?? [];

      debugPrint('Fetched ${studentsData.length} students');
      if (studentsData.isNotEmpty) {
        debugPrint('Sample student data: ${studentsData.first}');
      }

      students.value = studentsData.map((s) {
        // Backend returns nested personalInfo with firstNameAr/lastNameAr
        // Also has flat firstname/lastname fields
        String firstName = '';
        String lastName = '';

        // Try nested structure first (personalInfo.firstNameAr)
        if (s['personalInfo'] != null) {
          firstName = s['personalInfo']['firstNameAr'] ?? '';
          lastName = s['personalInfo']['lastNameAr'] ?? '';
        }

        // Fallback to flat fields
        if (firstName.isEmpty) {
          firstName = s['firstname'] ?? '';
        }
        if (lastName.isEmpty) {
          lastName = s['lastname'] ?? '';
        }

        String fullName = '$firstName $lastName'.trim();
        if (fullName.isEmpty) {
          fullName = 'طالب ${s['id']}'; // Fallback to "Student [ID]"
        }

        return {
          'id': s['id'],
          'name': fullName,
        };
      }).toList();

      debugPrint('Parsed ${students.length} students with names');
      isLoadingStudents.value = false;
    } catch (e) {
      debugPrint('Error fetching students: $e');
      isLoadingStudents.value = false;
    }
  }

  @override
  void dispose() {
    generate.dispose();
    Get.delete<Generate>();
    super.dispose();
  }

  @override
  List<Widget> formChild() {
    return [
      _buildGuardianSection(),
      const SizedBox(height: 10),
      _buildStudentSection(),
      const SizedBox(height: 10),
      _buildAccountSection(),
      const SizedBox(height: 10),
      // TODO: add profile Image section
    ];
  }

  Widget _buildGuardianSection() {
    return CustomContainer(
      headerText: "معلومات الوصي",
      headerIcon: Icons.person,
      child: Column(
        children: [
          _buildNameRow(),
          const SizedBox(height: 8),
          _buildRelationAndDobRow(),
          const SizedBox(height: 8),
          _buildContactRow(),
          const SizedBox(height: 8),
          _buildAddressAndJobRow(),
        ],
      ),
    );
  }

  Widget _buildStudentSection() {
    return CustomContainer(
      headerText: "الطالب",
      headerIcon: Icons.school,
      child: Obx(() {
        if (isLoadingStudents.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (students.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'لا يوجد طلاب متاحين',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return InputField(
          inputTitle: "اختر الطالب (اختياري)",
          child: DropdownButtonFormField<int>(
            value: selectedStudentId,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text('اختر طالب'),
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text('لا يوجد'),
              ),
              ...students.map((student) {
                return DropdownMenuItem<int>(
                  value: student['id'],
                  child: Text(student['name']),
                );
              }).toList(),
            ],
            onChanged: (value) {
              selectedStudentId = value;
              guardianInfo.studentId = value;
            },
            onSaved: (value) {
              guardianInfo.studentId = value;
            },
          ),
        );
      }),
    );
  }

  Widget _buildAccountSection() {
    return CustomContainer(
      headerIcon: Icons.account_box,
      headerText: "معلومات الحساب",
      child: Row(
        children: [
          Expanded(
            child: InputField(
              inputTitle: "اسم المستخدم",
              child: CustomTextField(
                controller: formController.controllers[8],
                onSaved: (p0) => guardianInfo.accountInfo.username = p0!,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InputField(
              inputTitle: "كلمة المرور",
              child: CustomTextField(
                controller: formController.controllers[9],
                onSaved: (p0) => guardianInfo.accountInfo.passcode = p0!,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameRow() {
    return Row(
      children: [
        Expanded(
          child: InputField(
            inputTitle: "الاسم الأول",
            child: CustomTextField(
              controller: formController.controllers[0],
              validator: (value) =>
                  Validator.notEmptyValidator(value, "يجب إدخال الاسم"),
              focusNode: formController.focusNodes[0],
              onSaved: (p0) => guardianInfo.guardian.firstName = p0!,
              onChanged: (_) => formController.controllers[8].text =
                  generate.generateUsername(formController.controllers[0],
                      formController.controllers[1]),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InputField(
            inputTitle: "اسم العائلة",
            child: CustomTextField(
              controller: formController.controllers[1],
              validator: (value) =>
                  Validator.notEmptyValidator(value, "يجب إدخال الاسم"),
              focusNode: formController.focusNodes[1],
              onSaved: (p0) => guardianInfo.guardian.lastName = p0!,
              onChanged: (_) => formController.controllers[8].text =
                  generate.generateUsername(formController.controllers[0],
                      formController.controllers[1]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRelationAndDobRow() {
    return Row(
      children: [
        Expanded(
          child: InputField(
            inputTitle: "العلاقة",
            child: DropDownWidget(
              items: relationship,
              initialValue:
                  editController?.model.value?.guardian.relationship ??
                      relationship[0],
              onSaved: (p0) => guardianInfo.guardian.relationship = p0!,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InputField(
            inputTitle: "تاريخ الميلاد",
            child: CustomTextField(
              controller: formController.controllers[3],
              readOnly: true,
              onTap: () async {
                DateTime initialDate = formController
                        .controllers[3].text.isNotEmpty
                    ? DateTime.tryParse(formController.controllers[3].text) ??
                        DateTime.now()
                    : DateTime.now();

                final pickedDate = await showCustomDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );

                if (pickedDate != null) {
                  formController.controllers[3].text =
                      "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                }
              },
              onSaved: (p0) => guardianInfo.guardian.dateOfBirth = p0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow() {
    return Row(
      children: [
        Expanded(
          child: InputField(
            inputTitle: "رقم الهاتف",
            child: CustomTextField(
              controller: formController.controllers[4],
              validator: (value) => Validator.isValidPhoneNumber(value),
              focusNode: formController.focusNodes[4],
              onSaved: (p0) => guardianInfo.contactInfo.phoneNumber = p0!,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InputField(
            inputTitle: "عنوان البريد الإلكتروني",
            child: CustomTextField(
              controller: formController.controllers[5],
              validator: (value) => Validator.isValidEmail(value),
              focusNode: formController.focusNodes[5],
              onSaved: (p0) => guardianInfo.contactInfo.email = p0!,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressAndJobRow() {
    return Row(
      children: [
        Expanded(
          child: InputField(
            inputTitle: "العنوان",
            child: CustomTextField(
              controller: formController.controllers[6],
              onSaved: (p0) => guardianInfo.guardian.homeAddress = p0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InputField(
            inputTitle: "الوظيفة",
            child: CustomTextField(
              controller: formController.controllers[7],
              onSaved: (p0) => guardianInfo.guardian.job = p0,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void setDefaultFieldsValue() {
    final s = editController?.model.value;
    formController.controllers[0].text = s?.guardian.firstName ?? '';
    formController.controllers[1].text = s?.guardian.lastName ?? '';
    formController.controllers[2].text = s?.guardian.relationship ?? '';
    formController.controllers[3].text = s?.guardian.dateOfBirth ?? '';
    formController.controllers[4].text = s?.contactInfo.phoneNumber ?? '';
    formController.controllers[5].text = s?.contactInfo.email ?? '';
    formController.controllers[6].text = s?.guardian.homeAddress ?? '';
    formController.controllers[7].text = s?.guardian.job ?? '';
    formController.controllers[8].text = s?.accountInfo.username ?? '';
    formController.controllers[9].text = s?.accountInfo.passcode ?? '';
  }

  @override
  Future<void> loadData() => Future(() {});

  @override
  Future<bool> submit() async {
    debugPrint('=== GUARDIAN SUBMIT START ===');

    if (!formKey.currentState!.validate()) {
      debugPrint('Validation failed');
      return false;
    }

    formKey.currentState!.save();
    debugPrint('Form saved');

    // Format data to match backend schema
    final body = {
      'guardian_info': {
        'first_name': guardianInfo.guardian.firstName,
        'last_name': guardianInfo.guardian.lastName,
        'relationship': guardianInfo.guardian.relationship,
        'date_of_birth': guardianInfo.guardian.dateOfBirth,
        'phone_number': guardianInfo.contactInfo.phoneNumber,
        'email': guardianInfo.contactInfo.email,
        'job': guardianInfo.guardian.job,
        'address': guardianInfo.guardian.homeAddress,
      },
      'account_info': {
        'username': guardianInfo.accountInfo.username,
        'password': guardianInfo.accountInfo.passcode,
      },
      if (guardianInfo.studentId != null) 'student_id': guardianInfo.studentId,
    };

    debugPrint('=== GUARDIAN BODY ===');
    debugPrint('Body: $body');
    debugPrint(
        'Guardian ID in guardianInfo: ${guardianInfo.guardian.guardianId}');

    try {
      final bool isEditMode = editController?.model.value != null;

      if (!isEditMode) {
        debugPrint('=== CREATE MODE ===');
        debugPrint('URL: ${ApiEndpoints.submitGuardianForm}');

        // Create mode - use ApiService
        final responseData = await ApiService.post(
          ApiEndpoints.submitGuardianForm,
          body,
          (json) => json,
        );

        debugPrint('=== RESPONSE RECEIVED ===');
        debugPrint('Response: $responseData');

        if (responseData['id'] != null) {
          guardianInfo.guardian.guardianId = responseData['id'];
          debugPrint('✅ Guardian created with ID: ${responseData['id']}');
        }
        return true;
      } else {
        // Edit mode - use guardian ID
        final guardianId = guardianInfo.guardian.guardianId;
        if (guardianId == null) {
          debugPrint('❌ Error: Guardian ID is null');
          return false;
        }

        debugPrint('=== EDIT MODE ===');
        debugPrint('Guardian ID: $guardianId');

        await ApiService.put(
          ApiEndpoints.getGuardianById(guardianId),
          body,
          (json) => json,
        );

        debugPrint('✅ Guardian updated successfully');
        return true;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error submitting guardian: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
}
