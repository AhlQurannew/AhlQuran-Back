import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/guardian.dart';
import '../models/student.dart';
import '../widgets/app_background.dart';
import 'profile_screen.dart';
import 'child_selection_screen.dart';
import 'attendance_ward_selection_screen.dart';
import 'statistics_ward_selection_screen.dart';
import 'achievements_ward_selection_screen.dart';

class ChildInfoScreen extends StatelessWidget {
  final LoginResponse loginResponse;
  final Student student;

  const ChildInfoScreen({
    super.key,
    required this.loginResponse,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Top card with My Ward icon and logo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          height: 80,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/landing/my-ward.svg',
                                    width: 48,
                                    height: 48,
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'My Ward',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                      height: 1.4,
                                      letterSpacing: -0.01,
                                      color: Color(0xFF000000),
                                    ),
                                  ),
                                ],
                              ),
                              SvgPicture.asset(
                                'assets/landing/logo-landing.svg',
                                width: 58,
                                height: 39.13,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Child Info title card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: const Text(
                            'Child Information',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 24,
                              height: 1.5,
                              color: Color(0xFF000000),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Scrollable info cards
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoCard(
                              'Name (English)',
                              student.personalInfo.firstNameEn ?? 'N/A',
                            ),
                            _buildInfoCard(
                              'Surname (English)',
                              student.personalInfo.lastNameEn ?? 'N/A',
                            ),
                            _buildInfoCard(
                              'Name (Arabic)',
                              student.personalInfo.firstNameAr ?? 'N/A',
                            ),
                            _buildInfoCard(
                              'Surname (Arabic)',
                              student.personalInfo.lastNameAr ?? 'N/A',
                            ),
                            _buildInfoCard(
                              'Gender',
                              student.personalInfo.sex ?? 'N/A',
                            ),
                            _buildInfoCard(
                              'Date of Birth',
                              student.personalInfo.dateOfBirth ?? 'N/A',
                            ),
                            _buildInfoCard(
                              'Place of Birth',
                              student.personalInfo.placeOfBirth ?? 'N/A',
                            ),
                            _buildInfoCard(
                              'Nationality',
                              student.personalInfo.nationality ?? 'N/A',
                            ),
                            _buildInfoCard(
                              'Home Address',
                              student.personalInfo.homeAddress ?? 'N/A',
                            ),
                            _buildInfoCard(
                              'Phone Number',
                              student.contactInfo.phoneNumber ?? 'N/A',
                            ),
                            _buildInfoCard(
                              'Email',
                              student.contactInfo.email ?? 'N/A',
                            ),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom navigation bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 104,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProfileScreen(loginResponse: loginResponse),
                              ),
                            );
                          },
                          child: _buildNavItem(Icons.person_outline, false),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChildSelectionScreen(
                                  loginResponse: loginResponse,
                                ),
                              ),
                            );
                          },
                          child: _buildNavItem(Icons.people_outline, false),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AttendanceWardSelectionScreen(
                                      loginResponse: loginResponse,
                                    ),
                              ),
                            );
                          },
                          child: _buildNavItem(
                            Icons.check_circle_outline,
                            false,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    StatisticsWardSelectionScreen(
                                      loginResponse: loginResponse,
                                    ),
                              ),
                            );
                          },
                          child: _buildNavItem(Icons.bar_chart_outlined, false),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AchievementsWardSelectionScreen(
                                      loginResponse: loginResponse,
                                    ),
                              ),
                            );
                          },
                          child: _buildNavItem(
                            Icons.psychology_outlined,
                            false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    // Check if value contains Arabic characters
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label : ',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      height: 1.5,
                      color: Color(0xFF000000),
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontFamily: hasArabic ? 'AbdoMisr' : 'Poppins',
                      fontWeight: FontWeight.w400,
                      fontSize: hasArabic ? 16 : 14,
                      height: 1.5,
                      color: const Color(0xFF000000),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return Container(
      width: 44,
      height: 48,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFFF6200).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(1000),
      ),
      child: Icon(
        icon,
        size: 24,
        color: isActive ? const Color(0xFFFF6200) : const Color(0xFF6C7278),
      ),
    );
  }
}
