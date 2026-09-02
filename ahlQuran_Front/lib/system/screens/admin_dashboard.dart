import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_controller.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Get.put to ensure controller exists, or Get.find if it was already created
    final AdminController adminController = Get.isRegistered<AdminController>()
        ? Get.find<AdminController>()
        : Get.put(AdminController());
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المسؤول'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => adminController.fetchPendingPresidents(),
            tooltip: 'تحديث',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                _showLogoutDialog(context, adminController, colorScheme),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.surface,
            ],
          ),
        ),
        child: Obx(() {
          if (adminController.isLoading.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'جاري تحميل الطلبات...',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }

          if (adminController.pendingPresidents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد طلبات معلقة',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'جميع الطلبات تمت الموافقة عليها',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: adminController.pendingPresidents.length,
            itemBuilder: (context, index) {
              final president = adminController.pendingPresidents[index];
              return _buildPresidentCard(
                context,
                president,
                adminController,
                colorScheme,
                textTheme,
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildPresidentCard(
    BuildContext context,
    dynamic president,
    AdminController adminController,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${president.firstname} ${president.lastname}',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'رئيس',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Details
            _buildDetailRow(
              Icons.email_outlined,
              'البريد الإلكتروني',
              president.email,
              colorScheme,
              textTheme,
            ),
            const SizedBox(height: 12),
            if (president.schoolName != null)
              _buildDetailRow(
                Icons.school_outlined,
                'اسم المدرسة',
                president.schoolName!,
                colorScheme,
                textTheme,
              ),
            if (president.schoolName != null) const SizedBox(height: 12),
            if (president.phoneNumber != null &&
                president.phoneNumber!.isNotEmpty)
              _buildDetailRow(
                Icons.phone_outlined,
                'رقم الهاتف',
                president.phoneNumber!,
                colorScheme,
                textTheme,
              ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showConfirmDialog(
                      context,
                      president,
                      adminController,
                      colorScheme,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle),
                    label: Text(
                      'قبول الطلب',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _showDetailsDialog(
                    context,
                    president,
                    colorScheme,
                    textTheme,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('تفاصيل'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    dynamic president,
    AdminController adminController,
    ColorScheme colorScheme,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('تأكيد القبول'),
        content: Text(
          'هل أنت متأكد من قبول طلب ${president.firstname} ${president.lastname}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              adminController.approvePresident(president.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('قبول'),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(
    BuildContext context,
    dynamic president,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text(
          'تفاصيل الطلب',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                Icons.badge,
                'رقم المعرف',
                president.id.toString(),
                colorScheme,
                textTheme,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.person,
                'الاسم الكامل',
                '${president.firstname} ${president.lastname}',
                colorScheme,
                textTheme,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.email,
                'البريد الإلكتروني',
                president.email,
                colorScheme,
                textTheme,
              ),
              if (president.schoolName != null) const SizedBox(height: 12),
              if (president.schoolName != null)
                _buildDetailRow(
                  Icons.school,
                  'اسم المدرسة',
                  president.schoolName!,
                  colorScheme,
                  textTheme,
                ),
              if (president.phoneNumber != null &&
                  president.phoneNumber!.isNotEmpty)
                const SizedBox(height: 12),
              if (president.phoneNumber != null &&
                  president.phoneNumber!.isNotEmpty)
                _buildDetailRow(
                  Icons.phone,
                  'رقم الهاتف',
                  president.phoneNumber!,
                  colorScheme,
                  textTheme,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    AdminController adminController,
    ColorScheme colorScheme,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              adminController.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
