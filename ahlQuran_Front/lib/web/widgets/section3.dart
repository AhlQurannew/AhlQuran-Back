import 'package:flutter/material.dart';
import './section_header.dart';

class Section3 extends StatelessWidget {
  const Section3({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SectionHeader(
            header: 'خصائص النظام',
          ),

          const SizedBox(height: 10),

          // Responsive grid for features
          LayoutBuilder(
            builder: (context, constraints) {
              final int crossAxisCount = constraints.maxWidth > 1000
                  ? 3
                  : constraints.maxWidth > 600
                      ? 2
                      : 1;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: const [
                  FeatureItem(
                    Icons.security,
                    'الأمن والحماية',
                    'تمّ تطوير النّظام باتّباع أفضل الممارسات التقنية وهذا لتوفير أفضل حماية ممكنة لبيانات مُستخدمينا وخصوصياتهم.',
                  ),
                  FeatureItem(
                    Icons.handshake,
                    'سهولة الاستخدام',
                    'لا يتطلّب استخدام النظام أي مهارات خاصة أو معلومات قبلية حول البرمجة وغيرها.',
                  ),
                  FeatureItem(
                    Icons.smartphone,
                    'توافق مع الأجهزة',
                    'يعمل النظام على جميع الأنظمة والمتصفّحات وشاشات اللمس، بالإضافة إلى تطبيق خاص بهواتف الأندرويد وآخر للأيفون',
                  ),
                  FeatureItem(
                    Icons.refresh,
                    'تحديث مستمر',
                    'تحديثات وتطويرات مستمرة على نظام أهل القرآن يستفيد منها المستخدمون بشكل دوريّ',
                  ),
                  FeatureItem(
                    Icons.cloud,
                    'نسخ احتياطي',
                    'نسخ احتياطي بشكل يوميّ لجميع البيانات المُدخلة.',
                  ),
                  FeatureItem(
                    Icons.notifications,
                    'نظام التنبيهات',
                    'نظام أوتوماتيكي للتنبيهات والإشعارات الآنية على الهواتف.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class FeatureItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;

  const FeatureItem(this.icon, this.title, this.description, {Key? key})
      : super(key: key);

  @override
  _FeatureItemState createState() => _FeatureItemState();
}

class _FeatureItemState extends State<FeatureItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered
            ? Matrix4.translationValues(0, -5, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: _isHovered ? 6 : 4,
              spreadRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon with hover color change
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                widget.icon,
                key: ValueKey<bool>(_isHovered),
                size: 40,
                color: _isHovered ? colorScheme.secondary : colorScheme.primary,
              ),
            ),
            const SizedBox(height: 15),
            // Feature title
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 10),
            // Feature description
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
