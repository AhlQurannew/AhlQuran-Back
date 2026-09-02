import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

// Dotted Border Button

class DottedBorderButton extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onTapUp;
  final String serviceName;
  final IconData serviceIcone;
  const DottedBorderButton({
    super.key,
    required this.onTap,
    required this.serviceName,
    required this.serviceIcone,
    required this.onTapUp,
  });

  @override
  State<DottedBorderButton> createState() => _DottedBorderButtonState();
}

class _DottedBorderButtonState extends State<DottedBorderButton> {
  bool isOn = false;

  void toggleSwitch() {
    setState(() {
      isOn = !isOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: GestureDetector(
        onTap: () {
          toggleSwitch();
          if (isOn) {
            widget.onTap();
          } else {
            widget.onTapUp();
          }
        },
        child: SizedBox(
          height: 100,
          width: 240,
          child: Stack(
            children: [
              // ColoredBox with the same dimensions and border radius as DottedBorder
              Positioned.fill(
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(10), // Match DottedBorder's radius
                  child: ColoredBox(
                    color: isOn ? colorScheme.primary : Colors.transparent,
                  ),
                ),
              ),
              // DottedBorder
              DottedBorder(
                color: colorScheme.secondary,
                radius: Radius.circular(10),
                borderType: BorderType.RRect,
                dashPattern: const [5, 2], // Dashed border pattern
                strokeWidth: 0.5,
                strokeCap: StrokeCap.round,
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.serviceName,
                        style: textTheme.bodyMedium?.copyWith(
                          color: isOn
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 10),
                      Icon(
                        widget.serviceIcone,
                        color: isOn
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
