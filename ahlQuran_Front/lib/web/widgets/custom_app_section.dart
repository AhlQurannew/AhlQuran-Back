import 'package:flutter/material.dart';
import 'section_header.dart'; // Make sure this path is correct.

/// A section showcasing custom school app pricing options.
class CustomAppPricingSection extends StatelessWidget {
  const CustomAppPricingSection({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        children: [
          const SectionHeader(
            header: "التطبيق المخصص",
            subheader:
                "يمكنك الحصول على تطبيق خاص بالمدرسة أو المؤسسة وفق هوية المدرسة.",
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWide ? 3 : 1,
                crossAxisSpacing: 25,
                mainAxisSpacing: 20,
                childAspectRatio: 1.7,
                children: [
                  PricingCard(
                    title: "تطبيق IOS و ANDROID",
                    price: "49900",
                    color: colorScheme.secondary,
                  ),
                  PricingCard(
                    title: "تطبيق IOS",
                    price: "29900",
                    color: colorScheme.secondary,
                  ),
                  PricingCard(
                    title: "تطبيق ANDROID",
                    price: "29900",
                    color: colorScheme.secondary,
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

/// A hoverable card displaying pricing info for a mobile app option.
class PricingCard extends StatefulWidget {
  final String title;
  final String price;
  final Color color;

  const PricingCard({
    super.key,
    required this.title,
    required this.price,
    required this.color,
  });

  @override
  State<PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<PricingCard> {
  double elevation = 0;
  double translateY = 0;

  void _onHover(bool hovering) {
    setState(() {
      elevation = hovering ? 8 : 0;
      translateY = hovering ? -5 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, translateY, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: elevation,
              offset: Offset(0, elevation / 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      "DA ${widget.price}",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Text(
                      "سنوياً",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
