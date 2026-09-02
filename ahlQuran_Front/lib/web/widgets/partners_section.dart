import 'dart:async';
import 'package:flutter/material.dart';

class PartnersSection extends StatefulWidget {
  const PartnersSection({super.key});

  @override
  _PartnersSectionState createState() => _PartnersSectionState();
}

class _PartnersSectionState extends State<PartnersSection> {
  final List<Map<String, String>> images = [
    {"image": "assets/partners/dz.jpg", "name": "الجزائر"},
    {"image": "assets/partners/maliz.jpg", "name": "ماليزيا"},
    {"image": "assets/partners/saud.jpg", "name": "السعودية"},
    {"image": "assets/partners/turq.jpg", "name": "تركيا"},
  ];

  final PageController _pageController = PageController();
  int currentIndex = 0;
  int itemsPerPage = 4; // Default: 4 cards per page

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Automatically switch pages every 5 seconds
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!mounted) return;
      setState(() {
        currentIndex = (currentIndex + itemsPerPage) % images.length;
        int targetPage = (currentIndex / itemsPerPage).floor();
        if (targetPage < (images.length / itemsPerPage).ceil()) {
          _pageController.animateToPage(
            targetPage,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive: 1 card per page on mobile, 4 on larger screens
    double screenWidth = MediaQuery.of(context).size.width;
    itemsPerPage = screenWidth < 600 ? 1 : 4;

    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.background,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            'شركاء النجاح',
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: _pageController,
              itemCount: (images.length / itemsPerPage).ceil(),
              itemBuilder: (context, pageIndex) {
                int startIndex = pageIndex * itemsPerPage;
                int endIndex =
                    (startIndex + itemsPerPage).clamp(0, images.length);
                List<Map<String, String>> displayedImages =
                    images.sublist(startIndex, endIndex);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: displayedImages.map((data) {
                    return _buildCard(context, data['image']!, data['name']!);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a partner card with image and name
  Widget _buildCard(BuildContext context, String imagePath, String name) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, imagePath),
      child: Column(
        children: [
          Container(
            width: 250,
            height: 210,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.asset(imagePath,
                  fit: BoxFit.cover, width: double.infinity),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 250,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              name,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the tapped image in a fullscreen dialog
  void _showFullScreenImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: InteractiveViewer(
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: AssetImage(imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
