import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Import your controllers here
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/profile_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/drawer_controller.dart'
    as mydrawer;
import 'package:the_doctarine_of_the_ppl_of_the_quran/routes/app_routes.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/messaging_dialog.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/settings_dialog.dart';

class CustomDrawer extends StatefulWidget {
  final bool miniMode;
  final Function()? onToggleMiniMode;

  const CustomDrawer({
    super.key,
    this.miniMode = false,
    this.onToggleMiniMode,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final profileController = Get.find<ProfileController>();
  final drawerController = Get.find<mydrawer.DrawerController>();

  // Get filtered menu items based on user role
  List<dynamic> get menuItems {
    final userRole = profileController.userRole.value.toLowerCase();
    final isTeacher = userRole == 'teacher';

    final allMenuItems = [
      {
        'type': 'item',
        'icon': Icons.dashboard,
        'title': 'لوحة القيادة',
        'route': Routes.dashboardPage,
      },
      {
        'type': 'item',
        'icon': Icons.chat,
        'title': 'غرفة المحادثة',
        'route': '/messages',
        'isDialog': true, // Special flag for dialog
      },
      {
        'type': 'item',
        'icon': Icons.settings,
        'title': 'الإعدادات',
        'route': '/settings',
        'isDialog': true, // Special flag for dialog
      },
      {'type': 'section', 'title': 'الشؤون الإدارية'},
      {
        'type': 'item',
        'icon': Icons.people,
        'title': 'الطلاب',
        'route': Routes.addStudent,
      },
      // Hide Teachers menu for teachers
      if (!isTeacher)
        {
          'type': 'item',
          'icon': Icons.person_outline,
          'title': 'المعلمين',
          'route': Routes.addTeacher,
        },
      // Hide Guardians menu for teachers
      if (!isTeacher)
        {
          'type': 'item',
          'icon': Icons.family_restroom,
          'title': 'أولياء الأمور',
          'route': Routes.addGuardian,
        },
      {
        'type': 'item',
        'icon': Icons.menu_book,
        'title': 'الحلقات',
        'route': Routes.addLecture,
      },
      {
        'type': 'item',
        'icon': Icons.check_box,
        'title': 'الحفظ والمراجعة',
        'route': Routes.trackAndMemorize,
      },
    ];

    return allMenuItems;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(34),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(5, 0),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(34),
        ),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        child: Container(
          width: widget.miniMode ? 70 : 280,
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Color.fromARGB(255, 219, 219, 219),
                width: 1.0,
              ),
            ),
          ),
          child: Column(
            children: [
              // Custom Header
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4DB6AC), // Mint green background
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: widget.miniMode
                    ? Center(
                        child: IconButton(
                          icon: const Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 28,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: widget.onToggleMiniMode,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Column 1: Logo (right side)
                          Image.asset(
                            'assets/logos/ahlQuran.png',
                            height: 50,
                            width: 50,
                            fit: BoxFit.contain,
                          ),
                          // Column 2: Text (middle)
                          Expanded(
                            child: Text(
                              'نظام اهل القرآن',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // Column 3: Hamburger menu (left side)
                          IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: 28,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: widget.onToggleMiniMode,
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 8),
              // User Profile Section
              if (!widget.miniMode) _buildUserProfile(),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  // Rebuild menu when role changes
                  final items = menuItems;
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      if (item['type'] == 'section') {
                        if (widget.miniMode) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Text(
                            item['title'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: const Color(0xFFD4AF37), // Gold color
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return Obx(() => _buildMenuItem(
                            context,
                            item['icon'],
                            item['title'],
                            item['route'],
                            index,
                            selected:
                                drawerController.selectedIndex.value == index,
                            isDialog: item['isDialog'] ?? false,
                          ));
                    },
                  );
                }),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    const goldColor = Color(0xFFD4AF37);
    const mintGreen = Color(0xFF4DB6AC);

    return Obx(() {
      final role = profileController.userRole.value;
      final firstName = profileController.firstName.value;
      final lastName = profileController.lastName.value;
      final displayName = (firstName.isNotEmpty || lastName.isNotEmpty)
          ? '$firstName $lastName'.trim()
          : profileController.userName.value;

      // Map role to Arabic and image
      String roleArabic = 'مستخدم';
      String imagePath = 'assets/images1/admin.png';

      switch (role.toLowerCase()) {
        case 'president':
          roleArabic = 'المشرف العام';
          imagePath = 'assets/images1/president.png';
          break;
        case 'supervisor':
        case 'superviser':
          roleArabic = 'المشرف';
          imagePath = 'assets/images1/supervisor.png';
          break;
        case 'teacher':
          roleArabic = 'المعلم';
          imagePath = 'assets/images1/teacher.png';
          break;
        case 'student':
          roleArabic = 'الطالب';
          imagePath = 'assets/images1/student.png';
          break;
        case 'parent':
          roleArabic = 'ولي الأمر';
          imagePath = 'assets/images1/parent.png';
          break;
        case 'admin':
          roleArabic = 'المدير';
          imagePath = 'assets/images1/admin.png';
          break;
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            // Circle with image and status tag
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // White circle with gray border
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Golden status tag at bottom
                Positioned(
                  bottom: -5,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: goldColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'متصل',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // User name
            Text(
              displayName,
              style: const TextStyle(
                color: mintGreen,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            // User role
            Text(
              roleArabic,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String route,
    int index, {
    bool selected = false,
    bool isDialog = false,
  }) {
    final theme = Theme.of(context);
    final mintGreen = const Color(0xFF4DB6AC); // Mint green color
    final iconColor = selected ? Colors.white : mintGreen;
    final textColor = selected ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? mintGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: widget.miniMode
            ? InkWell(
                onTap: () {
                  if (isDialog) {
                    // Show appropriate dialog based on route
                    if (route == '/messages') {
                      showDialog(
                        context: context,
                        builder: (context) => const MessagingDialog(),
                      );
                    } else if (route == '/settings') {
                      showDialog(
                        context: context,
                        builder: (context) => const SettingsDialog(),
                      );
                    }
                  } else {
                    drawerController.changeSelectedIndex(index);
                    Get.toNamed(route);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 24),
                ),
              )
            : ListTile(
                leading: Icon(icon, color: iconColor),
                title: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  if (isDialog) {
                    // Show appropriate dialog based on route
                    if (route == '/messages') {
                      showDialog(
                        context: context,
                        builder: (context) => const MessagingDialog(),
                      );
                    } else if (route == '/settings') {
                      showDialog(
                        context: context,
                        builder: (context) => const SettingsDialog(),
                      );
                    }
                  } else {
                    drawerController.changeSelectedIndex(index);
                    Get.toNamed(route);
                  }
                },
              ),
      ),
    );
  }
}
