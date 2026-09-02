import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/achivement_unit/surah_ayah.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/student_lecture_achievements.dart';
import '/system/widgets/input_field.dart';
import '../drop_down.dart';
import '../../../controllers/submit_form.dart';
import '../../models/post/acheivement.dart';

import '../custom_container.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/helpers/image.dart';
import '../../utils/const/acheivement.dart';
import '../acheivement_block.dart';
import '../../new_models/achivement_unit/surah_ayah_list.dart';
import '/controllers/latest_acheivement.dart';
import 'dart:developer' as dev;

/// URL for achievement data API endpoint
const String url = 'http://192.168.100.20/phpscript/acheivement_get_data.php';

/// A dialog widget for managing student achievements
class AcheivemtDialog extends StatefulWidget {
  final int sessionId;
  final int studentId;
  final String date;

  const AcheivemtDialog({
    super.key,
    required this.sessionId,
    required this.studentId,
    required this.date,
  });

  @override
  State<AcheivemtDialog> createState() => _AcheivemtDialogState();
}

class _AcheivemtDialogState extends State<AcheivemtDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final ScrollController _scrollController;
  final Acheivement _acheivement = Acheivement();
  final SurahAyahList _hifdList = SurahAyahList();
  final SurahAyahList _quickRevList = SurahAyahList();
  final SurahAyahList _majorRevList = SurahAyahList();

  final RxBool _isComplete = true.obs;
  final BeveledRectangleBorder _shape = const BeveledRectangleBorder();
  late final LatestAcheivement _latestAcheivement;
  late StudentLectureAchievements _latestInfo;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    _scrollController = ScrollController();
    _acheivement.lectureId = widget.sessionId;
    _acheivement.studentId = widget.studentId;
    _acheivement.date = widget.date;
    _latestAcheivement = Get.find<LatestAcheivement>();
    _loadLatestAchievement();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _latestAcheivement.clearController();
    _latestAcheivement.dispose();
    Get.delete<LatestAcheivement>();
    super.dispose();
  }

  Future<void> _loadLatestAchievement() async {
    try {
      _latestInfo =
          await _latestAcheivement.getData(widget.studentId, widget.sessionId);
      _latestAcheivement
          .assignControllerValue(_latestAcheivement.selectedType.value);
      Get.snackbar('Success', 'Achievement data loaded successfully');
    } catch (e) {
      debugPrint('Exception in _loadLatestAchievement: $e');
      Get.snackbar('Error', 'Failed to load achievement data');
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    _isComplete.value = false;

    try {
      // Assign SurahAyah lists to the Acheivement model
      _acheivement.hifd = _hifdList.surahAyahList;
      _acheivement.quickRev = _quickRevList.surahAyahList;
      _acheivement.majorRev = _majorRevList.surahAyahList;

      // Log form data for debugging
      dev.log(_acheivement.toJson().toString());

      // Submit form and get result
      final success =
          await submitForm(_formKey, _acheivement, url, Acheivement.fromJson);

      // Close dialog only on success
      if (success) {
        Get.back(result: true);
      }
    } catch (e) {
      // Show error if any exception occurs
      Get.snackbar('Error', 'Failed to submit achievement data');
      debugPrint('Error submitting form: $e');
    } finally {
      // Re-enable submit button
      _isComplete.value = true;
    }
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 50,
          color: colorScheme.primary,
        ),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ClipRRect(
            //"assets/back.png"
            child: CustomAssetImage(assetPath: "assets/back.png"),
          ),
        ),
        Row(
          children: [
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Get.back(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSessionInfo() {
    return CustomContainer(
      headerText: "latest session info",
      headerIcon: Icons.person,
      headerActions: [
        _buildCategoryTag(
          "memorization",
          const Color(0xFFe7b05d),
          AcheivementCategory.hifd,
        ),
        _buildCategoryTag(
          "quick revision",
          const Color(0xFF67bae0),
          AcheivementCategory.quickRev,
        ),
        _buildCategoryTag(
          "major revision",
          const Color(0xFF869456),
          AcheivementCategory.majorRev,
        ),
      ],
      child: Row(
        children: [
          _buildReadOnlyField("from surah", _latestAcheivement.fromSurah),
          const SizedBox(width: 8),
          _buildReadOnlyField("from ayah", _latestAcheivement.fromAyah),
          const SizedBox(width: 8),
          _buildReadOnlyField("to surah", _latestAcheivement.toSurah),
          const SizedBox(width: 8),
          _buildReadOnlyField("to ayah", _latestAcheivement.toAyah),
          const SizedBox(width: 8),
          _buildReadOnlyField("observation", _latestAcheivement.observation),
        ],
      ),
    );
  }

  Widget _buildCategoryTag(
      String tag, Color color, AcheivementCategory category) {
    return CreateSingleLineTag(
      tag: tag,
      color: color,
      onTap: () {
        setState(() {
          _latestAcheivement.updateSelectedType(category);
        });
      },
    );
  }

  Widget _buildReadOnlyField(String title, TextEditingController controller) {
    return Expanded(
      child: InputField(
        inputTitle: title,
        child: TextField(
          controller: controller,
          readOnly: true,
        ),
      ),
    );
  }

  Widget _buildAchievementSection(
    String title,
    SurahAyahList list,
    Function() onAdd,
  ) {
    return CustomContainer(
      headerText: title,
      headerIcon: Icons.person,
      headerActions: [
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
        ),
      ],
      child: Column(
        children: list.surahAyahList.asMap().entries.map((e) {
          return AcheivementBlock(
            key: ValueKey(e.value.key),
            surahAyah: e.value,
            onDelete: () {
              setState(() {
                list.removeSurahAyah(e.key);
              });
            },
            onSave: () {
              switch (title) {
                case "memorization":
                  _acheivement.hifd = list.surahAyahList;
                  break;
                case "quick revision":
                  _acheivement.quickRev = list.surahAyahList;
                  break;
                case "major revision":
                  _acheivement.majorRev = list.surahAyahList;
                  break;
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOtherSection() {
    return CustomContainer(
      headerText: "other",
      headerIcon: Icons.question_mark,
      child: Row(
        children: [
          Expanded(
            child: InputField(
              inputTitle: "presence state",
              child: DropDownWidget(
                items: presenceState,
                initialValue: presenceState[0],
                onSaved: (p0) => _acheivement.attendanceStatus = p0!,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InputField(
              inputTitle: "teacher note",
              child: TextFormField(
                onSaved: (p0) => _acheivement.teacherNote = p0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: Get.width * 0.7,
        maxHeight: Get.height * 0.8,
        minHeight: 400,
        minWidth: 300,
      ),
      child: Dialog(
        shape: _shape,
        backgroundColor: colorScheme.surface,
        child: Scrollbar(
          controller: _scrollController,
          child: Column(
            children: [
              _buildHeader(colorScheme),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildSessionInfo(),
                        const SizedBox(height: 10),
                        _buildAchievementSection(
                          "memorization",
                          _hifdList,
                          () => setState(() => _hifdList.addSurahAyah()),
                        ),
                        const SizedBox(height: 10),
                        _buildAchievementSection(
                          "quick revision",
                          _quickRevList,
                          () => setState(() => _quickRevList.addSurahAyah()),
                        ),
                        const SizedBox(height: 10),
                        _buildAchievementSection(
                          "major revision",
                          _majorRevList,
                          () => setState(() => _majorRevList.addSurahAyah()),
                        ),
                        const SizedBox(height: 10),
                        _buildOtherSection(),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  child: Obx(() => _isComplete.value
                      ? const Text("Submit")
                      : const CircularProgressIndicator()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that creates a single-line tag with a specific color and tap action
class CreateSingleLineTag extends StatelessWidget {
  final String tag;
  final Color color;
  final VoidCallback onTap;

  const CreateSingleLineTag({
    required this.tag,
    required this.color,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(tag),
        backgroundColor: color,
        labelPadding: const EdgeInsets.all(2),
      ),
    );
  }
}

/// Generates SurahAyah tags from a list of SurahAyah objects
Widget generateSurahAyahTags(List<SurahAyah> content, ColorScheme colorscheme) {
  return Wrap(
    spacing: 3,
    runSpacing: 3,
    children: content
        .map((e) =>
            createMultiLineTag(e.fromSurahName!, e.toSurahName!, colorscheme))
        .toList(),
  );
}

/// Creates a multi-line tag with two lines of text
Widget createMultiLineTag(String first, String last, ColorScheme colorscheme) =>
    Chip(
      labelPadding: const EdgeInsets.all(2),
      backgroundColor: colorscheme.primary,
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(first),
          Text(last),
        ],
      ),
    );
