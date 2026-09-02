import 'package:flutter/material.dart';
import './section_header.dart';

/// A responsive section displaying additional service cards.
class AdditionalServicesSection extends StatelessWidget {
  const AdditionalServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cards = [
      {
        "title": "الشؤون المالية",
        "price": "دج 19900",
        "description": [
          "اشتراكات الطلاب",
          "رواتب المعلمين والموظفين",
          "إدارة المداخيل والمصاريف",
        ],
        "icon": Icons.attach_money,
      },
      {
        "title": "الموقع التعريفي",
        "price": "دج 19900",
        "description": [
          "التسجيل الإلكتروني",
          "مكتبة المدرسة",
          "أنشطة وأخبار المدرسة",
        ],
        "icon": Icons.web,
      },
      {
        "title": "الرسائل الخاصة",
        "price": "دج 9900",
        "description": [
          "التواصل بين الجميع",
          "رسائل خاصة وجماعية",
          "تنبيهات فورية",
        ],
        "icon": Icons.message,
      },
      {
        "title": "المقرأة الإلكترونية",
        "price": "دج 9900",
        "description": [
          "حلقات افتراضية",
          "وقت غير محدود",
          "غرف فردية وجماعية",
        ],
        "icon": Icons.video_call,
      },
    ];

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
      child: Column(
        children: [
          const SectionHeader(header: "الخدمات الإضافية"),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount;
              double aspectRatio;

              if (constraints.maxWidth > 800) {
                crossAxisCount = 4;
                aspectRatio = 0.8;
              } else if (constraints.maxWidth > 600) {
                crossAxisCount = 2;
                aspectRatio = 0.9;
              } else {
                crossAxisCount = 1;
                aspectRatio = 1.5;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 15,
                  childAspectRatio: aspectRatio,
                ),
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return ServiceCard(
                    title: card['title'] as String,
                    price: card['price'] as String,
                    description: List<String>.from(card['description'] as List),
                    icon: card['icon'] as IconData,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A service card with a hover zoom effect (desktop/web).
class ServiceCard extends StatefulWidget {
  final String title;
  final String price;
  final List<String> description;
  final IconData icon;

  const ServiceCard({
    super.key,
    required this.title,
    required this.price,
    required this.description,
    required this.icon,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: isHovered
            ? Matrix4.translationValues(0, -5, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: isHovered ? 12 : 6,
              offset: Offset(0, isHovered ? 4 : 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 50, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              widget.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.price,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: widget.description.map(
                (item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
