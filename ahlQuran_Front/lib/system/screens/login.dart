import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/responsive_split_view.dart';
import '../../system/widgets/login.dart';
// leftchild: MyWidget(), rightchild: Text("Right Side"),

class LogInPage extends StatelessWidget {
  const LogInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveSplitView(
      primaryChild: const LogIn(),
      secondaryChild: Container(
        color: theme.primaryColor,
        child: Center(
          child: SvgPicture.asset(
            'assets/illustration/welcome-sign.svg',
            width: 400,
            height: 400,
            fit: BoxFit.contain,
            placeholderBuilder: (context) => const SizedBox(
              width: 400,
              height: 400,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
