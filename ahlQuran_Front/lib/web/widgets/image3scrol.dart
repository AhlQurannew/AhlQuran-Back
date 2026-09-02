import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class ImageCarousel3 extends StatelessWidget {
  // List of image asset paths
  final List<String> imagePaths =
      List.generate(13, (index) => 'assets/image${index + 1}.png');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor, // Use app theme background
      padding: const EdgeInsets.symmetric(vertical: 20), // Vertical padding
      child: Column(
        children: [
          Text(
            "هيئات تستعمل النظام",
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold), // Use theme text style
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          CarouselSlider(
            options: CarouselOptions(
              height: 200, // Carousel height
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              viewportFraction: 0.2, // Show 5 images at once
              enableInfiniteScroll: true,
              enlargeCenterPage: false,
            ),
            items: imagePaths.map((path) {
              return Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 5), // Space between images
                decoration: BoxDecoration(
                  color: theme
                      .cardColor, // Use theme card color for image background
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    path,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
