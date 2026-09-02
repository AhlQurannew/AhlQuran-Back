import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/generic_edit_controller.dart';
import '../../new_models/guardian.dart';
import '../../new_models/lecture.dart';
import '../../services/network/api_endpoints.dart';
import './dialog.dart';
import './guardian.dart';
import '../../services/api_client.dart';
import '../custom_container.dart';
import '../input_field.dart';
import '../../../controllers/validator.dart';
import '../../new_models/student.dart';
import '../multiselect.dart';
import '../../utils/const/student.dart';
import '../../../controllers/generate.dart';
import '../drop_down.dart';
import '../../../controllers/form_controller.dart' as form;
import './image_picker_widget.dart';
import '../../../helpers/date_picker.dart';

class StudentDialog<GEC extends GenericEditController<Student>>
    extends GlobalDialog {
  const StudentDialog({
    super.key,
    super.dialogHeader = "إضافة طالب",
    super.numberInputs = 15,
  });

  @override
  State<GlobalDialog> createState() =>
      _StudentDialogState<GenericEditController<Student>>();
}

class _StudentDialogState<GEC extends GenericEditController<Student>>
    extends DialogState<GEC> {
  late Generate generate;
  Student studentInfo = Student();
  bool isClicked = false; //TODO   remove this variable if not needed
  RxBool isExempt = false.obs;
  Rx<String?> enrollmentDate = Rxn<String>();
  Rx<String?> exitDate = Rxn<String>();
  MultiSelectResult<Lecture>? sessionResult;
  MultiSelectResult<Guardian>? guardianResult;
  //late Picker imagePicker;

  @override
  Future<void> loadData() async {
    try {
      final fetchedSessionNames =
          await getItems<Lecture>(ApiEndpoints.getLectures, Lecture.fromJson);
      final fetchedGuardianAccounts = await getItems<Guardian>(
          ApiEndpoints.getGuardianAccounts, Guardian.fromJson);

      dev.log('sessionNames: ${fetchedSessionNames.toString()}');
      dev.log('guardianAccounts: ${fetchedGuardianAccounts.toString()}');

      setState(() {
        sessionResult = fetchedSessionNames;
        guardianResult = fetchedGuardianAccounts;
      });
    } catch (e) {
      dev.log("Error loading data: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    generate = Get.isRegistered<Generate>()
        ? Get.find<Generate>()
        : Get.put(Generate());

    if (editController?.model.value != null) {
      // In edit mode, use the original reference - no deep copy needed
      studentInfo = editController!.model.value!;
    } else {
      // In create mode, generate password and set account type
      formController.controllers[7].text = generate.generatePassword();
      studentInfo.accountInfo.accountType = "طالب";
    }
  }

  @override
  void dispose() {
    generate.dispose();
    if (Get.isRegistered<Generate>()) {
      Get.delete<Generate>();
    }
    super.dispose();
  }

  @override
  List<Widget> formChild() {
    return [
      SessionSection(
        sessionResult: sessionResult,
        editController: editController,
        studentInfo: studentInfo,
      ),
      PersonalInfoSection(
        formController: formController,
        editController: editController,
        studentInfo: studentInfo,
        generate: generate,
      ),
      AccountInfoSection(
        formController: formController,
        studentInfo: studentInfo,
      ),
      ContactInfoSection(
        formController: formController,
        studentInfo: studentInfo,
      ),
      ParentStatusSection(
        editController: editController,
        studentInfo: studentInfo,
      ),
      GuardianInfoSection(
        guardianResult: guardianResult,
        studentInfo: studentInfo,
        editController: editController,
        onAddGuardian: () async {
          // Clean up any existing guardian form controller
          if (Get.isRegistered<form.FormController>(tag: 'guardian')) {
            Get.delete<form.FormController>(tag: 'guardian');
          }

          // Initialize FormController for guardian dialog with tag
          Get.put(form.FormController(10), tag: 'guardian');

          // Use the SAME GuardianDialog as the standalone page
          final result = await Get.dialog(
            const GuardianDialog(dialogHeader: 'إضافة وصي'),
            barrierDismissible: false,
          );

          if (result == true) {
            // Guardian was created successfully, reload the guardian list
            try {
              final fetchedGuardianAccounts = await getItems<Guardian>(
                  ApiEndpoints.getGuardianAccounts, Guardian.fromJson);

              setState(() {
                guardianResult = fetchedGuardianAccounts;

                // Auto-select the last added guardian (most recent)
                if (guardianResult?.items != null &&
                    guardianResult!.items!.isNotEmpty) {
                  final lastGuardian = guardianResult!.items!.last.obj;
                  studentInfo.guardian = lastGuardian;
                }
              });
            } catch (e) {
              dev.log("Error reloading guardians: $e");
            }
          }

          // Clean up guardian form controller after a delay to avoid disposal errors
          Future.delayed(const Duration(milliseconds: 100), () {
            if (Get.isRegistered<form.FormController>(tag: 'guardian')) {
              Get.delete<form.FormController>(tag: 'guardian');
            }
          });
        },
      ),
      FormalEducationSection(
        formController: formController,
        editController: editController,
        studentInfo: studentInfo,
      ),
    ];
  }

  @override
  void setDefaultFieldsValue() {
    final s = editController?.model.value;
    if (s == null) return;

    // Copy data to studentInfo first
    studentInfo.personalInfo = s.personalInfo;
    studentInfo.accountInfo = s.accountInfo;
    studentInfo.contactInfo = s.contactInfo;
    studentInfo.medicalInfo = s.medicalInfo;
    studentInfo.guardian = s.guardian;
    studentInfo.lectures = List.from(s.lectures);
    studentInfo.formalEducationInfo = s.formalEducationInfo;
    studentInfo.subscriptionInfo = s.subscriptionInfo;

    // Pre-fill form controllers
    formController.controllers[0].text = s.personalInfo.firstNameAr ?? '';
    formController.controllers[1].text = s.personalInfo.lastNameAr ?? '';
    formController.controllers[2].text = s.personalInfo.firstNameEn ?? '';
    formController.controllers[3].text = s.personalInfo.lastNameEn ?? '';
    formController.controllers[4].text = s.personalInfo.dateOfBirth ?? '';
    formController.controllers[5].text = s.personalInfo.homeAddress ?? '';
    formController.controllers[6].text = s.accountInfo.username ?? '';
    formController.controllers[7].text = s.accountInfo.passcode ?? '';
    formController.controllers[8].text = s.medicalInfo.diseasesCauses ?? '';
    formController.controllers[9].text = s.medicalInfo.allergies ?? '';
    formController.controllers[10].text = s.contactInfo.phoneNumber ?? '';
    formController.controllers[11].text = s.contactInfo.email ?? '';
    formController.controllers[12].text = s.subscriptionInfo.exitReason ?? '';
    formController.controllers[13].text =
        s.formalEducationInfo.schoolName ?? '';
    formController.controllers[14].text = s.personalInfo.placeOfBirth ?? '';

    // Pre-fill date pickers
    enrollmentDate.value = s.subscriptionInfo.enrollmentDate;
    exitDate.value = s.subscriptionInfo.exitDate;

    // Pre-fill subscription checkbox
    isExempt.value = s.subscriptionInfo.isExemptFromPayment == 1;
  }

  @override
  Future<bool> submit() async {
    if (!formKey.currentState!.validate()) return false;
    formKey.currentState!.save();

    if (editController?.model.value == null) {
      // Create Mode
      try {
        dev.log("=== STUDENT CREATION START ===");
        dev.log("Guardian ID before check: ${studentInfo.guardian.guardianId}");
        dev.log(
            "Guardian name: ${studentInfo.guardian.firstName} ${studentInfo.guardian.lastName}");

        // Check if guardian needs to be created first (temporary ID -1 or null)
        if (studentInfo.guardian.guardianId == null ||
            studentInfo.guardian.guardianId == -1) {
          dev.log("Creating new guardian first...");

          // Get phone number from guardianContactId (where we temporarily stored it)
          final phoneNumber = studentInfo.guardian.guardianContactId ??
              studentInfo.contactInfo.phoneNumber;

          // Create guardian first
          final guardianBody = {
            'guardian_info': {
              'first_name': studentInfo.guardian.firstName,
              'last_name': studentInfo.guardian.lastName,
              'relationship': studentInfo.guardian.relationship,
              'date_of_birth': studentInfo.guardian.dateOfBirth,
              'phone_number': phoneNumber,
              'email': studentInfo.guardian.email,
              'job': studentInfo.guardian.job,
              'address': studentInfo.guardian.homeAddress,
            },
            'account_info': {
              'username': studentInfo.guardian.email, // Use email as username
              'password': phoneNumber, // Use phone as password
            },
            // No student_id here - will be linked when student is created
          };

          // Create guardian and get the response with real ID
          final guardianResponse = await ApiService.post(
            ApiEndpoints.submitGuardianForm,
            guardianBody,
            (json) => json, // Return raw JSON
          );

          // Extract guardian ID from response
          if (guardianResponse['id'] != null) {
            studentInfo.guardian.guardianId = guardianResponse['id'];
            dev.log("Guardian created with ID: ${guardianResponse['id']}");
          } else {
            dev.log("Error: Guardian creation did not return an ID");
            return false;
          }
        } else {
          dev.log(
              "Using existing guardian with ID: ${studentInfo.guardian.guardianId}");
        }

        dev.log("=== CREATING STUDENT ===");
        // Now create student with the real guardian ID
        final body = {
          'personalInfo': studentInfo.personalInfo.toJson(),
          'accountInfo': studentInfo.accountInfo.toJson(),
          'contactInfo': studentInfo.contactInfo.toJson(),
          'guardian': studentInfo.guardian.toJson(),
          'lectures': studentInfo.lectures.map((e) => e.toJson()).toList(),
          'formalEducationInfo': studentInfo.formalEducationInfo.toJson(),
        };

        dev.log("Sending POST to: ${ApiEndpoints.submitStudentForm}");
        await ApiService.post(
          ApiEndpoints.submitStudentForm,
          body,
          Student.fromJson,
        );
        dev.log("=== STUDENT CREATED SUCCESSFULLY ===");
        return true;
      } catch (e) {
        dev.log("Error submitting student: $e");
        return false;
      }
    } else {
      // Edit Mode - Use full update endpoint
      final studentId = editController?.model.value?.personalInfo.studentId;

      if (studentId == null) {
        dev.log("Error: Student ID is null");
        return false;
      }

      final body = {
        'personalInfo': studentInfo.personalInfo.toJson(),
        'accountInfo': studentInfo.accountInfo.toJson(),
        'contactInfo': studentInfo.contactInfo.toJson(),
        'guardian': studentInfo.guardian.toJson(),
        'lectures': studentInfo.lectures.map((e) => e.toJson()).toList(),
        'formalEducationInfo': studentInfo.formalEducationInfo.toJson(),
      };

      try {
        await ApiService.put(
          ApiEndpoints.updateStudentFull(studentId),
          body,
          Student.fromJson,
        );
        return true;
      } catch (e) {
        dev.log("Error updating student: $e");
        return false;
      }
    }
  }
}

// Session Section
class SessionSection extends StatelessWidget {
  final MultiSelectResult<Lecture>? sessionResult;
  final GenericEditController<Student>? editController;
  final Student studentInfo;

  const SessionSection({
    super.key,
    required this.sessionResult,
    required this.editController,
    required this.studentInfo,
  });

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      headerIcon: Icons.book,
      headerText: "الحلقات",
      child: MultiSelect<Lecture>(
        initialPickedItems: (editController?.model.value?.lectures ?? [])
            .map((e) => MultiSelectItem<Lecture>(
                  id: e.lectureId,
                  obj: e,
                  name: e.lectureNameAr,
                ))
            .toList(),
        getPickedItems: (pickedItems) {
          studentInfo.lectures = pickedItems.map((e) => e.obj).toList();
        },
        hintText: "البحث عن الحلقات",
        preparedData: sessionResult?.items ?? [],
        maxSelectedItems: null,
      ),
    );
  }
}

// Personal Info Section
class PersonalInfoSection extends StatelessWidget {
  final form.FormController formController;
  final GenericEditController<Student>? editController;
  final Student studentInfo;
  final Generate generate;

  const PersonalInfoSection({
    super.key,
    required this.formController,
    required this.editController,
    required this.studentInfo,
    required this.generate,
  });

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      headerIcon: Icons.person,
      headerText: "معلومات الطالب الشخصية",
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InputField(
                  inputTitle: "الاسم الأول بالعربية",
                  child: CustomTextField(
                    controller: formController.controllers[0],
                    validator: (value) =>
                        Validator.notEmptyValidator(value, "يجب إدخال الاسم"),
                    focusNode: formController.focusNodes[0],
                    onSaved: (p0) => studentInfo.personalInfo.firstNameAr = p0!,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputField(
                  inputTitle: "اسم العائلة بالعربية",
                  child: CustomTextField(
                    controller: formController.controllers[1],
                    validator: (value) =>
                        Validator.notEmptyValidator(value, "يجب إدخال الاسم"),
                    focusNode: formController.focusNodes[1],
                    onSaved: (p0) => studentInfo.personalInfo.lastNameAr = p0!,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InputField(
                  inputTitle: "الاسم الأول باللاتينية",
                  child: CustomTextField(
                    controller: formController.controllers[2],
                    textDirection: TextDirection.ltr,
                    onChanged: (_) => formController.controllers[6].text =
                        generate.generateUsername(formController.controllers[2],
                            formController.controllers[3]),
                    onSaved: (p0) => studentInfo.personalInfo.firstNameEn = p0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputField(
                  inputTitle: "اسم العائلة باللاتينية",
                  child: CustomTextField(
                    controller: formController.controllers[3],
                    textDirection: TextDirection.ltr,
                    onChanged: (_) => formController.controllers[6].text =
                        generate.generateUsername(formController.controllers[2],
                            formController.controllers[3]),
                    onSaved: (p0) => studentInfo.personalInfo.lastNameEn = p0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InputField(
                  inputTitle: "الجنس",
                  child: DropDownWidget(
                    items: sex,
                    initialValue: editController?.model.value != null
                        ? editController?.model.value?.personalInfo.sex
                        : sex[0],
                    onSaved: (p0) => studentInfo.personalInfo.sex = p0!,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputField(
                  inputTitle: "تاريخ الميلاد",
                  child: CustomTextField(
                    controller: formController.controllers[4],
                    readOnly: true,
                    onTap: () async {
                      DateTime initialDate;
                      if (formController.controllers[4].text.isNotEmpty) {
                        initialDate = DateTime.tryParse(
                                formController.controllers[4].text) ??
                            DateTime.now();
                      } else {
                        initialDate = DateTime.now();
                      }

                      final pickedDate = await showCustomDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );

                      if (pickedDate != null) {
                        formController.controllers[4].text =
                            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                      }
                    },
                    onSaved: (p0) => studentInfo.personalInfo.dateOfBirth = p0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InputField(
                  inputTitle: "مكان الميلاد",
                  child: CustomTextField(
                    controller: formController.controllers[14],
                    onSaved: (p0) => studentInfo.personalInfo.placeOfBirth = p0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputField(
                  inputTitle: "العنوان",
                  child: CustomTextField(
                    controller: formController.controllers[5],
                    onSaved: (p0) => studentInfo.personalInfo.homeAddress = p0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InputField(
                  inputTitle: "الجنسية",
                  child: DropDownWidget(
                    items: nationalities,
                    initialValue:
                        editController?.model.value?.personalInfo.nationality ??
                            nationalities[1],
                    onSaved: (p0) => studentInfo.personalInfo.nationality = p0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Account Info Section
// Account Info Section
class AccountInfoSection extends StatefulWidget {
  final form.FormController formController;
  final Student studentInfo;

  const AccountInfoSection({
    super.key,
    required this.formController,
    required this.studentInfo,
  });

  @override
  State<AccountInfoSection> createState() => _AccountInfoSectionState();
}

class _AccountInfoSectionState extends State<AccountInfoSection> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      headerIcon: Icons.account_box,
      headerText: "معلومات الحساب",
      child: Row(
        children: [
          Expanded(
            child: InputField(
              inputTitle: "اسم المستخدم",
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: CustomTextField(
                  controller: widget.formController.controllers[6],
                  textDirection: TextDirection.ltr,
                  onSaved: (p0) =>
                      widget.studentInfo.accountInfo.username = p0!,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InputField(
              inputTitle: "كلمة المرور",
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: CustomTextField(
                  controller: widget.formController.controllers[7],
                  textDirection: TextDirection.ltr,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  onSaved: (p0) =>
                      widget.studentInfo.accountInfo.passcode = p0!,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Health Info Section
class HealthInfoSection extends StatelessWidget {
  final form.FormController formController;
  final GenericEditController<Student>? editController;
  final Student studentInfo;

  const HealthInfoSection({
    super.key,
    required this.formController,
    required this.editController,
    required this.studentInfo,
  });

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      headerIcon: Icons.health_and_safety,
      headerText: "المعلومات الصحية",
      child: Row(
        children: [
          Expanded(
            child: InputField(
              inputTitle: "فصيلة الدم",
              child: DropDownWidget(
                items: bloodType,
                initialValue:
                    editController?.model.value?.medicalInfo.bloodType ??
                        bloodType[0],
                onSaved: (p0) => studentInfo.medicalInfo.bloodType = p0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InputField(
              inputTitle: "أسباب الأمراض",
              child: CustomTextField(
                controller: formController.controllers[8],
                onSaved: (p0) => studentInfo.medicalInfo.diseasesCauses = p0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InputField(
              inputTitle: "الحساسية",
              child: CustomTextField(
                controller: formController.controllers[9],
                onSaved: (p0) => studentInfo.medicalInfo.allergies = p0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Contact Info Section
class ContactInfoSection extends StatelessWidget {
  final form.FormController formController;
  final Student studentInfo;

  const ContactInfoSection({
    super.key,
    required this.formController,
    required this.studentInfo,
  });

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      headerIcon: Icons.phone,
      headerText: "معلومات الاتصال",
      child: Row(
        children: [
          Expanded(
            child: InputField(
              inputTitle: "رقم الهاتف",
              child: CustomTextField(
                controller: formController.controllers[10],
                validator: (value) => Validator.isValidPhoneNumber(value),
                focusNode: formController.focusNodes[10],
                onSaved: (p0) => studentInfo.contactInfo.phoneNumber = p0!,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InputField(
              inputTitle: "عنوان البريد الإلكتروني",
              child: CustomTextField(
                controller: formController.controllers[11],
                validator: (value) => Validator.isValidEmail(value),
                focusNode: formController.focusNodes[11],
                onSaved: (p0) => studentInfo.contactInfo.email = p0!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Parent Status Section
class ParentStatusSection extends StatelessWidget {
  final GenericEditController<Student>? editController;
  final Student studentInfo;

  const ParentStatusSection({
    super.key,
    required this.editController,
    required this.studentInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomContainer(
            headerIcon: Icons.person,
            headerText: "حالة الأب",
            child: DropDownWidget(
              items: state,
              initialValue:
                  editController?.model.value?.personalInfo.fatherStatus ??
                      state[0],
              onSaved: (p0) => studentInfo.personalInfo.fatherStatus = p0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomContainer(
            headerIcon: Icons.person,
            headerText: "حالة الأم",
            child: DropDownWidget(
              items: state,
              initialValue:
                  editController?.model.value?.personalInfo.motherStatus ??
                      state[0],
              onSaved: (p0) => studentInfo.personalInfo.motherStatus = p0,
            ),
          ),
        ),
      ],
    );
  }
}

// Guardian Info Section
class GuardianInfoSection extends StatelessWidget {
  final MultiSelectResult<Guardian>? guardianResult;
  final Student studentInfo;
  final GenericEditController<Student>? editController;
  final VoidCallback? onAddGuardian;

  const GuardianInfoSection({
    super.key,
    required this.guardianResult,
    required this.studentInfo,
    this.editController,
    this.onAddGuardian,
  });

  @override
  Widget build(BuildContext context) {
    // Create initial picked item if guardian exists from edit mode
    List<MultiSelectItem<Guardian>>? initialPickedGuardian;
    if (editController?.model.value?.guardian != null &&
        editController!.model.value!.guardian.guardianId != null) {
      final guardian = editController!.model.value!.guardian;
      initialPickedGuardian = [
        MultiSelectItem<Guardian>(
          id: guardian.guardianId ?? 0,
          obj: guardian,
          name: "${guardian.firstName ?? ''} ${guardian.lastName ?? ''}".trim(),
        )
      ];
    }

    return CustomContainer(
      headerIcon: Icons.family_restroom,
      headerText: "معلومات عن الوصي",
      headerActions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: IconButton(
            onPressed: onAddGuardian,
            icon: Icon(
              Icons.add,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
        ),
      ],
      child: Row(
        children: [
          Expanded(
            child: InputField(
              inputTitle: "حساب الوصي",
              child: MultiSelect<Guardian>(
                initialPickedItems: initialPickedGuardian,
                getPickedItems: (pickedItems) {
                  if (pickedItems.isNotEmpty) {
                    studentInfo.guardian = pickedItems[0].obj;
                    dev.log(
                        "Selected guardian: ${studentInfo.guardian.firstName} ${studentInfo.guardian.lastName}");
                    dev.log("Guardian ID: ${studentInfo.guardian.guardianId}");
                  }
                },
                preparedData: guardianResult?.items ?? [],
                hintText: "البحث عن حساب الوصي",
                maxSelectedItems: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Subscription Info Section
class SubscriptionInfoSection extends StatelessWidget {
  final form.FormController formController;
  final GenericEditController<Student>? editController;
  final Student studentInfo;
  final Rx<String?> enrollmentDate;
  final Rx<String?> exitDate;
  final RxBool isExempt;

  const SubscriptionInfoSection({
    super.key,
    required this.formController,
    required this.editController,
    required this.studentInfo,
    required this.enrollmentDate,
    required this.exitDate,
    required this.isExempt,
  });

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      headerText: "معلومات الاشتراك",
      headerIcon: Icons.subscriptions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRow(context),
          const SizedBox(height: 12),
          _buildExemptRow(),
          const SizedBox(height: 12),
          _buildExitReasonField(),
        ],
      ),
    );
  }

  /// Row containing enrollment and exit date pickers
  Widget _buildDateRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildEnrollmentDatePicker(context)),
        const SizedBox(width: 12),
        Expanded(child: _buildExitDatePicker(context)),
      ],
    );
  }

  /// Row containing isExempt and exemption percentage dropdowns
  Widget _buildExemptRow() {
    return Row(
      children: [
        Expanded(child: _buildIsExemptDropdown()),
        const SizedBox(width: 12),
        Expanded(child: _buildExemptionPercentageDropdown()),
      ],
    );
  }

  /// Full width exit reason field
  Widget _buildExitReasonField() {
    return InputField(
      inputTitle: "سبب الخروج",
      child: CustomTextField(
        controller: formController.controllers[12],
        onSaved: (p0) => studentInfo.subscriptionInfo.exitReason = p0,
        maxLines: 3,
      ),
    );
  }

  Widget _buildEnrollmentDatePicker(BuildContext context) {
    return InputField(
      inputTitle: "تاريخ التسجيل",
      child: Obx(() => OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              minimumSize: const Size(0, 36), // small button height
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4), // more square
              ),
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            onPressed: () async {
              final date = await showCustomDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                final dateStr = "${date.year}-${date.month}-${date.day}";
                enrollmentDate.value = dateStr;
                studentInfo.subscriptionInfo.enrollmentDate = dateStr;
              }
            },
            child: Text(enrollmentDate.value ?? "اختر التاريخ"),
          )),
    );
  }

  Widget _buildExitDatePicker(BuildContext context) {
    return InputField(
      inputTitle: "تاريخ الخروج",
      child: Obx(() => OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              minimumSize: const Size(0, 36), // small button height
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4), // more square
              ),
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            onPressed: () async {
              final date = await showCustomDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                final dateStr = "${date.year}-${date.month}-${date.day}";
                exitDate.value = dateStr;
                studentInfo.subscriptionInfo.exitDate = dateStr;
              }
            },
            child: Text(exitDate.value ?? "اختر التاريخ"),
          )),
    );
  }

  Widget _buildIsExemptDropdown() {
    return InputField(
      inputTitle: "معفى من الدفع",
      child: DropDownWidget<bool>(
        items: trueFalse,
        initialValue: (editController
                ?.model.value?.subscriptionInfo.isExemptFromPayment ==
            1),
        onChanged: (p0) => isExempt.value = p0!,
        onSaved: (p0) => studentInfo.subscriptionInfo.isExemptFromPayment =
            p0 == true ? 1 : 0,
      ),
    );
  }

  Widget _buildExemptionPercentageDropdown() {
    return Obx(() => Visibility(
          visible: isExempt.value,
          child: InputField(
            inputTitle: "نسبة الإعفاء",
            child: DropDownWidget(
              items: const ["25%", "50%", "75%", "100%"],
              initialValue: "100%", // Default
              onSaved: (p0) {
                // Logic to save percentage if needed
              },
            ),
          ),
        ));
  }
}

// Formal Education Section
class FormalEducationSection extends StatelessWidget {
  final form.FormController formController;
  final GenericEditController<Student>? editController;
  final Student studentInfo;

  const FormalEducationSection({
    super.key,
    required this.formController,
    required this.editController,
    required this.studentInfo,
  });

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      headerIcon: Icons.school,
      headerText: "معلومات الدراسة النظامية",
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InputField(
                  inputTitle: "المستوى الدراسي",
                  child: DropDownWidget(
                    items: academicLevel,
                    initialValue: academicLevel.contains(editController
                            ?.model.value?.formalEducationInfo.academicLevel)
                        ? editController!
                            .model.value!.formalEducationInfo.academicLevel
                        : academicLevel[0],
                    onSaved: (p0) =>
                        studentInfo.formalEducationInfo.academicLevel = p0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputField(
                  inputTitle: "الصف الدراسي",
                  child: DropDownWidget(
                    items: grades,
                    initialValue: grades.contains(editController
                            ?.model.value?.formalEducationInfo.grade)
                        ? editController!.model.value!.formalEducationInfo.grade
                        : grades[0],
                    onSaved: (p0) => studentInfo.formalEducationInfo.grade = p0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InputField(
                  inputTitle: "المدرسة",
                  child: CustomTextField(
                    controller: formController.controllers[13],
                    onSaved: (p0) =>
                        studentInfo.formalEducationInfo.schoolName = p0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Image Section
class ImageSection extends StatelessWidget {
  final GenericEditController<Student>? editController;

  const ImageSection({
    super.key,
    required this.editController,
  });

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      headerIcon: Icons.image,
      headerText: "الصورة الشخصية",
      child: Column(
        children: [
          InputField(
            inputTitle: "صورة",
            child: ImagePickerWidget(
              onImagePicked: (file) {
                // Handle image pick
              },
            ),
          ),
          const SizedBox(height: 12),
          InputField(
            inputTitle: "صورة الهوية الوجه 1",
            child: ImagePickerWidget(
              onImagePicked: (file) {
                // Handle ID image pick
              },
            ),
          ),
        ],
      ),
    );
  }
}
