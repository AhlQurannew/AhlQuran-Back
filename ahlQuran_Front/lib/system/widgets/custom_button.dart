import 'package:flutter/material.dart';
import 'package:flutter_animated_button/flutter_animated_button.dart';

//Custom Button
class CustomButton extends StatefulWidget {
  final double y;
  final GlobalKey<FormState> formKey;
  final VoidCallback toggleAnimation;
  final VoidCallback onPressFunction;
  const CustomButton({
    super.key,
    required this.y,
    required this.formKey,
    required this.toggleAnimation,
    required this.onPressFunction,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (event) => widget.toggleAnimation(),
      onExit: (event) => widget.toggleAnimation(),
      child: Transform.translate(
        offset: Offset(0, -widget.y * 5),
        child: Container(
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ]),
          child: AnimatedButton(
            text: 'تأكيد الطلب',
            textStyle: textTheme.titleMedium ?? const TextStyle(fontSize: 16),
            textOverflow: TextOverflow.visible,
            isReverse: true,
            onPress: widget.onPressFunction,
            transitionType: TransitionType.CENTER_LR_IN,
            borderRadius: 5,
            backgroundColor: colorScheme.primary,
            selectedBackgroundColor: colorScheme.secondary,
            selectedTextColor: colorScheme.onSecondary,
            animationDuration: Duration(seconds: 1),
            animatedOn: AnimatedOn.onHover,
          ),
        ),
      ),
    );
  }
}
