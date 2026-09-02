import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/charts/chart_filter_controller.dart';

class ChartData {
  final String x;
  final String category;
  final double y;

  ChartData(this.x, this.category, this.y);
}

class DateChartData {
  final DateTime x;
  final String category;
  final double y;

  DateChartData(this.x, this.category, this.y);
}

Widget buildFiltersWithActions(
  BuildContext context,
  String tag, {
  VoidCallback? onSearch,
  VoidCallback? onReset,
}) {
  final controller = Get.find<ChartFilterController>(tag: tag);

  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildFieldColumn(
            "إلى تاريخ",
            _buildDateField(context, controller, isFrom: false),
          ),
          _buildFieldColumn(
            "من تاريخ",
            _buildDateField(context, controller, isFrom: true),
          ),
          _buildFieldColumn(
            "اسم المحاضرة",
            _buildDropdown(controller.lectureNameController, context),
          ),
          _buildFieldColumn(
            "اسم الطالب",
            _buildDropdown(controller.studentNameController, context),
          ),
          ElevatedButton.icon(
            onPressed: () {
              controller.applyFilters();
              onSearch?.call();
            },
            icon: const Icon(Icons.search, size: 18),
            label: const Text("بحث"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              controller.resetFilters();
              onReset?.call();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text("إعادة تعيين"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildFieldColumn(String label, Widget field) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          label,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      field,
    ],
  );
}

Widget _buildDropdown(TextEditingController controller, BuildContext context) {
  return ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 160, maxWidth: 180),
    child: TextField(
      controller: controller,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        hintText: "اكتب هنا",
        hintStyle: const TextStyle(),
      ),
    ),
  );
}

Widget _buildDateField(
  BuildContext context,
  ChartFilterController controller, {
  required bool isFrom,
}) {
  return ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 160, maxWidth: 180),
    child: InkWell(
      onTap: () => controller.pickDate(context, isFrom: isFrom),
      child: InputDecorator(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
        child: Obx(() {
          final date =
              isFrom ? controller.fromDate.value : controller.toDate.value;
          return Text(
            date != null
                ? DateFormat('d MMM yyyy', 'ar').format(date)
                : "اختر التاريخ",
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.right,
          );
        }),
      ),
    ),
  );
}

Widget buildChartContainer({required Widget child, Key? key}) {
  return Card(
    key: key,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}

Widget buildLoadingIndicator() {
  return const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: CircularProgressIndicator(),
    ),
  );
}

Widget buildEmptyState(String message) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, color: Colors.grey),
      ),
    ),
  );
}
