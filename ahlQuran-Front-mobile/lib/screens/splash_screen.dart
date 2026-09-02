import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _textController;
  late AnimationController _titleController;
  late AnimationController _buttonController;

  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotateAnimation;
  late Animation<double> _iconFadeAnimation;

  late Animation<double> _textScaleAnimation;
  late Animation<double> _textFadeAnimation;

  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;

  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _buttonFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Icon animation controller
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Text (book) animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Title animation controller
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Button animation controller
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Icon animations - scale, rotate, and fade
    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _iconRotateAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _iconFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Text (book) animations - scale and fade with bounce
    _textScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Title animations
    _titleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _titleController, curve: Curves.easeIn));

    _titleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _titleController, curve: Curves.easeOutCubic),
        );

    // Button animations
    _buttonScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.elasticOut),
    );

    _buttonFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _buttonController, curve: Curves.easeIn));

    // Start animations in sequence
    _startAnimations();
    _navigateToHome();
  }

  Future<void> _startAnimations() async {
    // Start icon animation
    await Future.delayed(const Duration(milliseconds: 300));
    _iconController.forward();

    // Start text animation
    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();

    // Start title animation
    await Future.delayed(const Duration(milliseconds: 800));
    _titleController.forward();

    // Start button animation
    await Future.delayed(const Duration(milliseconds: 500));
    _buttonController.forward();
  }

  Future<void> _navigateToHome() async {
    // Wait for animations to complete
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Check if user is already logged in
    final authService = AuthService();
    final loginData = await authService.getStoredLoginData();

    if (!mounted) return;

    if (loginData != null) {
      // User is logged in, go to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(loginResponse: loginData),
        ),
      );
    } else {
      // User is not logged in, go to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    _titleController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Icon with scale, rotate, and fade animation
            AnimatedBuilder(
              animation: _iconController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _iconScaleAnimation.value,
                  child: Transform.rotate(
                    angle: _iconRotateAnimation.value,
                    child: Opacity(
                      opacity: _iconFadeAnimation.value,
                      child: SvgPicture.asset(
                        'assets/images/logo_icon.svg',
                        width: 108,
                        height: 119,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Logo Text (Book shape) with scale and fade animation
            AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _textScaleAnimation.value,
                  child: Opacity(
                    opacity: _textFadeAnimation.value,
                    child: SvgPicture.asset(
                      'assets/images/logo_text.svg',
                      width: 208,
                      height: 46,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // "Doctrine Quran" Text with gradient and animation
            FadeTransition(
              opacity: _titleFadeAnimation,
              child: SlideTransition(
                position: _titleSlideAnimation,
                child: ShaderMask(
                  shaderCallback: (bounds) => const RadialGradient(
                    center: Alignment.center,
                    radius: 0.5,
                    colors: [
                      Color(0xFFFFD29F), // #FFD29F
                      Color(0xFFFF8800), // #FF8800
                      Color(0xFFFF6200), // #FF6200
                    ],
                    stops: [0.0, 0.2404, 1.0],
                  ).createShader(bounds),
                  child: Text(
                    'Doctrine\nQuran',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quando(
                      fontSize: 50.5946,
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          offset: Offset(0, 4),
                          blurRadius: 4,
                          color: Color.fromRGBO(0, 0, 0, 0.25),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Orange circle button with chevron
            AnimatedBuilder(
              animation: _buttonController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _buttonScaleAnimation.value,
                  child: Opacity(
                    opacity: _buttonFadeAnimation.value,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            center: Alignment(-0.5, -0.5), // Top left
                            radius: 1.2,
                            colors: [
                              Color(0xFFFFD29F), // #FFD29F
                              Color(0xFFFF8800), // #FF8800
                              Color(0xFFFF6200), // #FF6200
                            ],
                            stops: [0.0, 0.2404, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFF6200,
                              ).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
