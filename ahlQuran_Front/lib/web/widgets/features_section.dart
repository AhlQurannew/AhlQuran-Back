import 'package:flutter/material.dart';

import './section_header.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SectionHeader(
            header: 'مزايا النظام',
          ),
          SizedBox(height: 10),
          SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 1000 ? 3 : 1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: const [
              FeatureItem(Icons.group, 'إدارة شؤون الحلقات',
                  'تشمل كلّ ما يتعلّق بالحلقات من انشاء الحلقات و إضافة وإسناد الطّلاب والمعلّمين وغيرها من العمليّات التنظيمية.'),
              FeatureItem(Icons.person, 'إدارة الطّلاب والمعلّمين',
                  'تشمل كلّ ما يتعلق بالطالب والمعلّم، بداية من التسجيل في المدرسة.. مروراً بكافّة العمليات التّعليمية والإدارية.'),
              FeatureItem(Icons.videocam, 'المقرأة الإلكترونية',
                  'يستطيع المعلّم بواسطة نظام أهل القرآن الاجتماع مع طلّابه من خلال المقرأة الإلكترونية على شكل حلقات افتراضية تختصر الجهد والوقت والمسافات.'),
              FeatureItem(Icons.article, 'التقارير',
                  'تقارير كتابية وبيانية شاملة، حول الحلقات والحفظ والمراجعة والحضور والغياب، يستفيد منها المشرف والمعلّم وكذا الطالب ووليّ الأمر.'),
              FeatureItem(Icons.mic, 'متابعة الحفظ والمراجعة',
                  'وذلك بمتابعة الطّالب بشكل تفصيليّ، مع إمكانية تحديد أخطائه على المصحف ليستفيد منها في رحلة حفظه.'),
              FeatureItem(Icons.wifi, 'إدارة الأخبار والإعلانات',
                  'يتميّز النظام بمنصّة لإدارة الأخبار المتعلّقة بالمدرسة، ليكون الطّالب ووليّ أمره على اطّلاع مستمر بكافّة أحداث وفعاليات المدرسة القرآنية.'),
            ],
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
  final VoidCallback? onTap;

  const FeatureItem(
    this.icon,
    this.title,
    this.description, {
    super.key,
    this.onTap,
  });

  @override
  _FeatureItemState createState() => _FeatureItemState();
}

class _FeatureItemState extends State<FeatureItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered
            ? Matrix4.translationValues(0, -6, 0)
            : Matrix4.identity(),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(100),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                ),
                child: Icon(
                  widget.icon,
                  size: 40,
                  color:
                      _isHovered ? colorScheme.secondary : colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
