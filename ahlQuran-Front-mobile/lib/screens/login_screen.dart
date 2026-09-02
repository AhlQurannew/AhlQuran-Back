import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/app_background.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  bool _emailTouched = false;
  bool _passwordTouched = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    if (!_emailTouched) {
      setState(() {
        _emailTouched = true;
      });
    }

    setState(() {
      if (value.isEmpty) {
        _emailError = 'Please enter your email';
      } else if (!value.contains('@')) {
        _emailError = 'Please enter a valid email';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword(String value) {
    if (!_passwordTouched) {
      setState(() {
        _passwordTouched = true;
      });
    }

    setState(() {
      if (value.isEmpty) {
        _passwordError = 'Please enter your password';
      } else if (value.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
      } else {
        _passwordError = null;
      }
    });
  }

  Future<void> _handleLogin() async {
    // Validate all fields
    _validateEmail(_emailController.text);
    _validatePassword(_passwordController.text);

    if (_emailError != null || _passwordError != null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final loginResponse = await _authService.guardianLogin(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DashboardScreen(loginResponse: loginResponse),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // White blur ellipse inside card
                        Positioned(
                          left: 192,
                          top: -170.5,
                          child: Container(
                            width: 320.5,
                            height: 320.5,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 65, sigmaY: 65),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Glassmorphic card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 343,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Logo and title section
                                    Column(
                                      children: [
                                        // Logo (book decoration only)
                                        SvgPicture.asset(
                                          'assets/images/logo_text.svg',
                                          width: 83.44,
                                          height: 18.16,
                                        ),
                                        const SizedBox(height: 5.14),

                                        // Doctrine Quran text with gradient
                                        ShaderMask(
                                          shaderCallback: (bounds) =>
                                              const RadialGradient(
                                                center: Alignment.center,
                                                radius: 0.5,
                                                colors: [
                                                  Color(0xFFFFD29F),
                                                  Color(0xFFFF8800),
                                                  Color(0xFFFF6200),
                                                ],
                                                stops: [0.0, 0.2404, 1.0],
                                              ).createShader(bounds),
                                          child: Text(
                                            'Doctrine\nQuran',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.quando(
                                              fontSize: 20.3243,
                                              fontWeight: FontWeight.w400,
                                              height: 1.0,
                                              color: Colors.white,
                                              shadows: const [
                                                Shadow(
                                                  offset: Offset(0, 1.60684),
                                                  blurRadius: 1.60684,
                                                  color: Color.fromRGBO(
                                                    0,
                                                    0,
                                                    0,
                                                    0.25,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    // Guardian Login title
                                    const Text(
                                      'Guardian Login',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 32,
                                        height: 1.3,
                                        letterSpacing: -0.64,
                                        color: Color(0xFF000000),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Subtitle
                                    const Text(
                                      'Enter your email and password to log in',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        height: 1.4,
                                        letterSpacing: -0.12,
                                        color: Color(0xFF6C7278),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Email field with external error
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 46,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                              color: _emailError != null
                                                  ? Colors.red
                                                  : const Color(0xFFEDF1F3),
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFE4E5E7,
                                                ).withValues(alpha: 0.24),
                                                offset: const Offset(0, 1),
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: TextFormField(
                                            controller: _emailController,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            onChanged: _validateEmail,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              height: 1.4,
                                              letterSpacing: -0.14,
                                              color: Color(0xFF1A1C1E),
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'yourname@gmail.com',
                                              hintStyle: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                                height: 1.4,
                                                letterSpacing: -0.14,
                                                color: const Color(
                                                  0xFF1A1C1E,
                                                ).withValues(alpha: 0.3),
                                              ),
                                              border: InputBorder.none,
                                              errorBorder: InputBorder.none,
                                              focusedErrorBorder:
                                                  InputBorder.none,
                                              errorStyle: const TextStyle(
                                                height: 0,
                                                fontSize: 0,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 13,
                                                  ),
                                            ),
                                            validator: (value) => _emailError,
                                          ),
                                        ),
                                        if (_emailError != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                              left: 4,
                                            ),
                                            child: Text(
                                              _emailError!,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 12,
                                                color: Colors.red,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Password field with external error
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 46,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                              color: _passwordError != null
                                                  ? Colors.red
                                                  : const Color(0xFFEDF1F3),
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFE4E5E7,
                                                ).withValues(alpha: 0.24),
                                                offset: const Offset(0, 1),
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: TextFormField(
                                            controller: _passwordController,
                                            obscureText: _obscurePassword,
                                            onChanged: _validatePassword,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              height: 1.4,
                                              letterSpacing: -0.14,
                                              color: Color(0xFF1A1C1E),
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Password',
                                              hintStyle: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                                height: 1.4,
                                                letterSpacing: -0.14,
                                                color: const Color(
                                                  0xFF1A1C1E,
                                                ).withValues(alpha: 0.3),
                                              ),
                                              border: InputBorder.none,
                                              errorBorder: InputBorder.none,
                                              focusedErrorBorder:
                                                  InputBorder.none,
                                              errorStyle: const TextStyle(
                                                height: 0,
                                                fontSize: 0,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 13,
                                                  ),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons
                                                            .visibility_off_outlined
                                                      : Icons
                                                            .visibility_outlined,
                                                  size: 16,
                                                  color: const Color(
                                                    0xFFACB5BB,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _obscurePassword =
                                                        !_obscurePassword;
                                                  });
                                                },
                                              ),
                                            ),
                                            validator: (value) =>
                                                _passwordError,
                                          ),
                                        ),
                                        if (_passwordError != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                              left: 4,
                                            ),
                                            child: Text(
                                              _passwordError!,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 12,
                                                color: Colors.red,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    // Login button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: Ink(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color(0x1FFFFFFF),
                                                Color(0x00FFFFFF),
                                              ],
                                            ),
                                            color: const Color(0xFFFF6A00),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Container(
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF6A00),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                : const Text(
                                                    'Login',
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 14,
                                                      height: 1.4,
                                                      letterSpacing: -0.14,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
