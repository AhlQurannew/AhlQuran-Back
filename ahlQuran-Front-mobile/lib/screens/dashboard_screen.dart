import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/guardian.dart';
import '../services/auth_service.dart';
import '../widgets/app_background.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'child_selection_screen.dart';
import 'attendance_ward_selection_screen.dart';
import 'achievements_ward_selection_screen.dart';
import 'statistics_ward_selection_screen.dart';
import 'graphs_ward_selection_screen.dart';

class DashboardScreen extends StatelessWidget {
  final LoginResponse loginResponse;

  const DashboardScreen({super.key, required this.loginResponse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Top bar with logout
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.logout,
                            color: Color(0xFFFF6200),
                          ),
                          onPressed: () async {
                            await AuthService().logout();
                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // Logo section
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: [
                        SvgPicture.asset(
                          'assets/landing/logo-landing.svg',
                          width: 94,
                          height: 64.3,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Welcome card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Text(
                            'Welcome Guardian ${loginResponse.user.firstname}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              fontSize: 20,
                              height: 1.4,
                              letterSpacing: -0.01,
                              color: Color(0xFF000000),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dashboard grid
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.7,
                        children: [
                          _buildDashboardItem(
                            'Me',
                            'assets/landing/me.svg',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(
                                    loginResponse: loginResponse,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildDashboardItem(
                            'My Ward',
                            'assets/landing/my-ward.svg',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChildSelectionScreen(
                                    loginResponse: loginResponse,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildDashboardItem(
                            'Acheivments',
                            'assets/landing/achievments.svg',
                            () {
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
                          ),
                          _buildDashboardItem(
                            'Presence',
                            'assets/landing/presence.svg',
                            () {
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
                          ),
                          _buildDashboardItem(
                            'Graphs',
                            'assets/landing/graphs.svg',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      GraphsWardSelectionScreen(
                                        loginResponse: loginResponse,
                                      ),
                                ),
                              );
                            },
                          ),
                          _buildDashboardItem(
                            'Statistics',
                            'assets/landing/stats.svg',
                            () {
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
                          ),
                        ],
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

  Widget _buildDashboardItem(
    String title,
    String iconPath,
    VoidCallback onTap,
  ) {
    return Stack(
      children: [
        // The card with icon
        _buildDashboardCard(iconPath, onTap),
        // Text positioned absolutely in the center
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                height: 1.4,
                letterSpacing: -0.01,
                color: Color(0xFF000000),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardCard(String iconPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Center(
              child: SvgPicture.asset(iconPath, width: 48, height: 48),
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
