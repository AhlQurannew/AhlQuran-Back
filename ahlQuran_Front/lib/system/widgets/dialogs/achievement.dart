import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as dev;
import '../../new_models/achievement.dart';
import '../../new_models/student.dart';
import '../../../data/quran_data.dart';
import '../../services/api_client.dart';
import '../../services/network/api_endpoints.dart';
import '../../utils/snackbar_helper.dart';
import '../../../controllers/profile_controller.dart';

class AchievementDialog extends StatefulWidget {
  final Student student;
  final String date;

  const AchievementDialog({
    super.key,
    required this.student,
    required this.date,
  });

  @override
  State<AchievementDialog> createState() => _AchievementDialogState();
}

class _AchievementDialogState extends State<AchievementDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Achievement> achievements = [];
  bool isLoading = true;
  bool isTeacher = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Check if user is a teacher
    try {
      final profileController = Get.find<ProfileController>();
      isTeacher = profileController.userRole.value.toLowerCase() == 'teacher';
      dev.log('User is teacher: $isTeacher');
    } catch (e) {
      dev.log('Error checking user role: $e');
      isTeacher = false;
    }
    
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      dev.log('Student ID: ${widget.student.id}');
      dev.log(
          'PersonalInfo StudentId: ${widget.student.personalInfo.studentId}');

      if (widget.student.id == null) {
        throw Exception('Student ID is null');
      }

      // Use teacher-specific endpoint if user is a teacher
      final endpoint = isTeacher
          ? ApiEndpoints.getMyStudentAchievements(widget.student.id!)
          : '${ApiEndpoints.getStudents}${widget.student.id}/achievements';
      
      dev.log('Loading achievements from: $endpoint');

      final response = await ApiService.fetchList(
        endpoint,
        Achievement.fromJson,
      );

      setState(() {
        achievements = response;
        isLoading = false;
      });
    } catch (e) {
      dev.log('Error loading achievements: $e');
      setState(() {
        achievements = [];
        isLoading = false;
      });
    }
  }

  Future<void> _deleteAchievement(Achievement achievement) async {
    try {
      if (widget.student.id == null) {
        throw Exception('Student ID is null');
      }

      // Use teacher-specific endpoint if user is a teacher
      final endpoint = isTeacher
          ? ApiEndpoints.deleteMyStudentAchievement(widget.student.id!, achievement.id!)
          : '${ApiEndpoints.getStudents}${widget.student.id}/achievements/${achievement.id}';

      await ApiService.delete(endpoint);
      showSuccessSnackbar('تم حذف الإنجاز بنجاح', context: context);
      _loadAchievements();
    } catch (e) {
      dev.log('Error deleting achievement: $e');
      showErrorSnackbar('فشل في حذف الإنجاز', context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studentName =
        '${widget.student.personalInfo.firstNameAr ?? ''} ${widget.student.personalInfo.lastNameAr ?? ''}';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(studentName),

            // Date and Student Info
            _buildInfoBar(),

            // Tab Bar
            _buildTabBar(),

            // Tab Content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAchievementList('حفظ'),
                        _buildAchievementList('مراجعة صغرى'),
                        _buildAchievementList('مراجعة كبرى'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String studentName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF4DB6AC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Text(
              'إنجاز الطالب(ة): $studentName',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () {
              try {
                Get.back();
              } catch (e) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFDEB059),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text(
                  'التاريخ:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.date,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF4DB6AC),
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black,
        tabs: const [
          Tab(text: 'حفظ'),
          Tab(text: 'مراجعة صغرى'),
          Tab(text: 'مراجعة كبرى'),
        ],
      ),
    );
  }

  Widget _buildAchievementList(String type) {
    String achievementType;
    if (type == 'حفظ') {
      achievementType = 'normal';
    } else if (type == 'مراجعة صغرى') {
      achievementType = 'small';
    } else {
      achievementType = 'big';
    }

    final filteredAchievements = achievements
        .where((a) => a.achievementType == achievementType)
        .toList();

    return Column(
      children: [
        // Add button and delete all button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddAchievementDialog(achievementType),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4DB6AC),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: filteredAchievements.isEmpty
                    ? null
                    : () => _showDeleteAllDialog(achievementType),
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('حذف البيانات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Achievement list with dates
        Expanded(
          child: filteredAchievements.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد بيانات $type',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredAchievements.length,
                  itemBuilder: (context, index) {
                    return _buildAchievementCard(
                      filteredAchievements[index],
                      type,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement, String type) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'من آية: ${achievement.fromVerse}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'من سورة: ${achievement.getFromSurahName()}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'إلى آية: ${achievement.toVerse}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'إلى سورة: ${achievement.getToSurahName()}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (achievement.note != null &&
                          achievement.note!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'العلامة: ${achievement.note}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    // Date badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDEB059),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        achievement.date.isNotEmpty ? achievement.date : '--',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Delete button
                    IconButton(
                      onPressed: () => _showDeleteConfirmDialog(achievement),
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAchievementDialog(String achievementType) {
    if (widget.student.id == null) {
      showErrorSnackbar('معرف الطالب غير صالح', context: context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddAchievementDialog(
        studentId: widget.student.id!,
        achievementType: achievementType,
        date: widget.date,
        existingAchievements: achievements,
        onSuccess: _loadAchievements,
      ),
    );
  }

  void _showDeleteConfirmDialog(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الإنجاز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAchievement(achievement);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(String achievementType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد حذف جميع البيانات'),
        content: const Text('هل أنت متأكد من حذف جميع البيانات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllAchievements(achievementType);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllAchievements(String achievementType) async {
    if (widget.student.id == null) {
      showErrorSnackbar('معرف الطالب غير صالح', context: context);
      return;
    }

    final filteredAchievements = achievements
        .where((a) => a.achievementType == achievementType)
        .toList();

    for (var achievement in filteredAchievements) {
      try {
        // Use teacher-specific endpoint if user is a teacher
        final endpoint = isTeacher
            ? ApiEndpoints.deleteMyStudentAchievement(widget.student.id!, achievement.id!)
            : '${ApiEndpoints.getStudents}${widget.student.id}/achievements/${achievement.id}';
        
        await ApiService.delete(endpoint);
      } catch (e) {
        dev.log('Error deleting achievement: $e');
      }
    }

    showSuccessSnackbar('تم حذف جميع البيانات بنجاح', context: context);
    _loadAchievements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Add Achievement Dialog
class AddAchievementDialog extends StatefulWidget {
  final int studentId;
  final String achievementType;
  final String date;
  final List<Achievement> existingAchievements;
  final VoidCallback onSuccess;

  const AddAchievementDialog({
    super.key,
    required this.studentId,
    required this.achievementType,
    required this.date,
    required this.existingAchievements,
    required this.onSuccess,
  });

  @override
  State<AddAchievementDialog> createState() => _AddAchievementDialogState();
}

class _AddAchievementDialogState extends State<AddAchievementDialog> {
  Surah? fromSurah;
  Surah? toSurah;
  int? fromVerse;
  int? toVerse;
  final TextEditingController noteController = TextEditingController();
  bool isSubmitting = false;
  bool isTeacher = false;

  @override
  void initState() {
    super.initState();
    
    // Check if user is a teacher
    try {
      final profileController = Get.find<ProfileController>();
      isTeacher = profileController.userRole.value.toLowerCase() == 'teacher';
      dev.log('User is teacher: $isTeacher');
    } catch (e) {
      dev.log('Error checking user role: $e');
      isTeacher = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'إضافة إنجاز',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // From Surah
            Row(
              children: [
                Expanded(
                  child: _buildSurahDropdown(
                    label: 'من سورة',
                    value: fromSurah,
                    onChanged: (value) {
                      setState(() {
                        fromSurah = value;
                        fromVerse = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildVerseDropdown(
                    label: 'من آية',
                    surah: fromSurah,
                    value: fromVerse,
                    onChanged: (value) {
                      setState(() {
                        fromVerse = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // To Surah
            Row(
              children: [
                Expanded(
                  child: _buildSurahDropdown(
                    label: 'إلى سورة',
                    value: toSurah,
                    onChanged: (value) {
                      setState(() {
                        toSurah = value;
                        toVerse = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildVerseDropdown(
                    label: 'إلى آية',
                    surah: toSurah,
                    value: toVerse,
                    onChanged: (value) {
                      setState(() {
                        toVerse = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Note
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'العلامة',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: isSubmitting ? null : _submitAchievement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4DB6AC),
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('حفظ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahDropdown({
    required String label,
    required Surah? value,
    required ValueChanged<Surah?> onChanged,
  }) {
    return DropdownButtonFormField<Surah>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: quranSurahs.map((surah) {
        return DropdownMenuItem(
          value: surah,
          child: Text('${surah.number}. ${surah.name}'),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildVerseDropdown({
    required String label,
    required Surah? surah,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: surah == null
          ? []
          : List.generate(surah.numberOfAyahs, (index) => index + 1)
              .map((verse) {
              return DropdownMenuItem(
                value: verse,
                child: Text('$verse'),
              );
            }).toList(),
      onChanged: surah == null ? null : onChanged,
    );
  }

  Future<void> _submitAchievement() async {
    if (fromSurah == null ||
        toSurah == null ||
        fromVerse == null ||
        toVerse == null) {
      showErrorSnackbar('الرجاء ملء جميع الحقول المطلوبة', context: context);
      return;
    }

    // Prevent reversing verses within the same chapter
    if (fromSurah!.number == toSurah!.number && fromVerse! > toVerse!) {
      _showTopErrorMessage('لا يمكن عكس الآيات في نفس السورة');
      return;
    }

    // Create temporary achievement for overlap checking
    final newAchievement = Achievement(
      studentId: widget.studentId,
      fromSurah: fromSurah!.number,
      toSurah: toSurah!.number,
      fromVerse: fromVerse!,
      toVerse: toVerse!,
      note: noteController.text.isEmpty ? null : noteController.text,
      achievementType: widget.achievementType,
      date: widget.date,
    );

    // Check for overlap only for 'normal' (حفظ) type
    if (_checkOverlap(newAchievement, widget.existingAchievements)) {
      _showTopErrorMessage('يوجد تداخل مع إنجاز حفظ موجود مسبقاً');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Use teacher-specific endpoint if user is a teacher
      final endpoint = isTeacher
          ? ApiEndpoints.createMyStudentAchievement(widget.studentId)
          : '${ApiEndpoints.getStudents}${widget.studentId}/achievements';
      
      await ApiService.post(
        endpoint,
        newAchievement.toJson(),
        Achievement.fromJson,
      );

      if (mounted) {
        Navigator.pop(context);
        showSuccessSnackbar('تم إضافة الإنجاز بنجاح', context: context);
        // Call onSuccess after closing dialog to reload achievements
        widget.onSuccess();
      }
    } catch (e) {
      dev.log('Error adding achievement: $e');
      if (mounted) {
        showErrorSnackbar('فشل في إضافة الإنجاز', context: context);
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void _showTopErrorMessage(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  bool _checkOverlap(
      Achievement newAchievement, List<Achievement> existingAchievements) {
    // Only check for 'normal' (حفظ) type
    if (newAchievement.achievementType != 'normal') {
      return false;
    }

    // Filter existing achievements to only check 'normal' type
    final normalAchievements = existingAchievements
        .where((a) => a.achievementType == 'normal')
        .toList();

    for (var existing in normalAchievements) {
      // Convert to absolute verse positions for easier comparison
      int newStart = _getAbsoluteVersePosition(
        newAchievement.fromSurah,
        newAchievement.fromVerse,
      );
      int newEnd = _getAbsoluteVersePosition(
        newAchievement.toSurah,
        newAchievement.toVerse,
      );
      int existingStart = _getAbsoluteVersePosition(
        existing.fromSurah,
        existing.fromVerse,
      );
      int existingEnd = _getAbsoluteVersePosition(
        existing.toSurah,
        existing.toVerse,
      );

      // Check if ranges overlap
      if (!(newEnd < existingStart || newStart > existingEnd)) {
        return true; // Overlap detected
      }
    }

    return false; // No overlap
  }

  int _getAbsoluteVersePosition(int surahNumber, int verseNumber) {
    // Calculate absolute position by summing all verses before this surah
    // plus the verse number in current surah
    int position = 0;
    for (int i = 1; i < surahNumber; i++) {
      final surah = getSurahByNumber(i);
      if (surah != null) {
        position += surah.numberOfAyahs;
      }
    }
    position += verseNumber;
    return position;
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }
}
