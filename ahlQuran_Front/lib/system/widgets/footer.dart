import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/helpers/lunch_url.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/helpers/image.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLinkColumn(context, "الدعم الفني", [
                {"title": "شروحات النظام", "route": "/tutorials"},
                {"title": "الأسئلة المتكررة", "route": "/faq"},
              ]),
              _buildLinkColumn(context, "روابط داخلية", [
                {"title": "صور من النظام", "route": "/system-images"},
                {"title": "صور من التطبيق", "route": "/app-images"},
                {"title": "خصائص النظام", "route": "/features"},
                {"title": "عملاؤنا", "route": "/customers"},
                {"title": "شركاء النجاح", "route": "/partners"},
              ]),
              _buildLinkColumn(context, "روابط سريعة", [
                {"title": "الرئيسية", "route": "/page1"},
                {"title": "أسعار النظام", "route": "/pricing"},
                {"title": "مدونة الموقع", "route": "/blog"},
                {"title": "طلب نسخة", "route": "/request"},
                {"title": "التسويق بالعمولة", "route": "/affiliate"},
              ]),
            ],
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => launchURL(
                    'https://apps.apple.com/us/app/example-app/id123456789'),
                child: CustomAssetImage(
                    assetPath: 'assets/footer/APP.png', height: 72),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => launchURL(
                    'https://play.google.com/store/apps/details?id=com.example.app'),
                child: CustomAssetImage(
                    assetPath: 'assets/footer/google-play.png', height: 50),
              ),
            ],
          ),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(FontAwesomeIcons.whatsapp,
                  color: colorScheme.primary, size: 30),
              const SizedBox(width: 10),
              FaIcon(FontAwesomeIcons.facebook,
                  color: colorScheme.secondary, size: 30),
              const SizedBox(width: 10),
              FaIcon(FontAwesomeIcons.twitter,
                  color: colorScheme.tertiary, size: 30),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            "جميع الحقوق محفوظة © نظام أهل القرآن",
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkColumn(
      BuildContext context, String title, List<Map<String, String>> links) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ...links.map((link) => AnimatedNavigationText(
            text: link["title"]!, routeName: link["route"]!))
      ],
    );
  }
}

class AnimatedNavigationText extends StatefulWidget {
  final String text;
  final String routeName;
  const AnimatedNavigationText({
    required this.text,
    required this.routeName,
    super.key,
  });

  @override
  State<AnimatedNavigationText> createState() => _AnimatedNavigationTextState();
}

class _AnimatedNavigationTextState extends State<AnimatedNavigationText>
    with SingleTickerProviderStateMixin {
  bool isHovered = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _animation = Tween<double>(begin: 0, end: 5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _animation.addListener(() {
      setState(() {});
    });
  }

  void toggleAnimation(bool hover) {
    if (hover) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      isHovered = hover;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => toggleAnimation(true),
      onExit: (_) => toggleAnimation(false),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, widget.routeName);
        },
        child: Transform.translate(
          offset: Offset(_animation.value, 0),
          child: Text(
            widget.text,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isHovered
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// Widget avec animation de survol
/*class AnimatedNavigationText extends StatefulWidget {
  final String text;
  final String routeName;

  const AnimatedNavigationText({required this.text, required this.routeName, Key? key}) : super(key: key);

  @override
  _AnimatedNavigationTextState createState() => _AnimatedNavigationTextState();
}

class _AnimatedNavigationTextState extends State<AnimatedNavigationText> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // Curseur en forme de main
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, widget.routeName);
        },
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontSize: isHovered ? 18 : 16, // Augmentation de la taille
            color: isHovered ? Color(0xFF0E9D6D) : Colors.black, // Changement de couleur
            fontWeight: isHovered ? FontWeight.bold : FontWeight.normal,
          ),
          child: Text(widget.text),
        ),
      ),
    );
  }
}*/
