import 'dart:async';
import 'package:flutter/material.dart';
import './section_header.dart';

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({super.key});
  @override
  _ImageCarouselState createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  // List of feature titles with icons
  final List<Map<String, dynamic>> features = [
    {'icon': Icons.assessment, 'title': 'Session Report'},
    {'icon': Icons.check_circle, 'title': 'Attendance Stats'},
    {'icon': Icons.trending_up, 'title': 'Performance Review'},
    {'icon': Icons.task_alt, 'title': 'Daily Tasks'},
    {'icon': Icons.schedule, 'title': 'Class Schedule'},
    {'icon': Icons.sports, 'title': 'Student Activities'},
    {'icon': Icons.admin_panel_settings, 'title': 'Admin Reports'},
    {'icon': Icons.book, 'title': 'Subjects'},
  ];

  final PageController _pageController = PageController();
  int currentIndex = 0;
  int itemsPerPage = 4; // Default: 4 cards per page

  @override
  void initState() {
    super.initState();
    // Auto-scroll timer
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          currentIndex = (currentIndex + itemsPerPage) % features.length;
          _pageController.animateToPage(
            currentIndex ~/ itemsPerPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Responsive: 2 cards on small screens, 4 on large
    double screenWidth = MediaQuery.of(context).size.width;
    itemsPerPage = screenWidth < 600 ? 2 : 4;

    final theme = Theme.of(context);

    return Column(
      children: [
        SectionHeader(
          header: 'مميزات المنصّة',
        ),
        const SizedBox(height: 40),
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _pageController,
            itemCount: (features.length / itemsPerPage).ceil(),
            itemBuilder: (context, pageIndex) {
              int startIndex = pageIndex * itemsPerPage;
              int endIndex =
                  (startIndex + itemsPerPage).clamp(0, features.length);
              List<Map<String, dynamic>> displayedFeatures =
                  features.sublist(startIndex, endIndex);

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: displayedFeatures.map((data) {
                  return _buildCard(
                      context, data['icon']!, data['title']!, theme);
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  // Builds a single feature card
  Widget _buildCard(
      BuildContext context, IconData icon, String title, ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 150,
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.2),
                blurRadius: 5,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 80,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 150,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.15),
                blurRadius: 3,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
