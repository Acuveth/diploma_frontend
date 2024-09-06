import 'package:flutter/material.dart';
import "../theme/theme.dart";

class MyTextButton extends StatelessWidget {
  const MyTextButton({
    Key? key,
    required this.buttonName,
    required this.onTap,
    this.bgColor,
    this.textColor,
  }) : super(key: key);

  final String buttonName;
  final Function onTap;
  final Color? bgColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    // Detect the current theme and set the button background color accordingly
    final Color backgroundColor = bgColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white // Dark theme
            : kBackgroundColor); // Light theme

    final Color fontColor = textColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? kBackgroundColor // Dark theme
            : Colors.white); // Light theme

    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextButton(
        style: ButtonStyle(
          overlayColor: MaterialStateProperty.resolveWith(
                (states) => Colors.black12,
          ),
        ),
        onPressed: () => onTap(),
        child: Text(
          buttonName,
          style: kButtonText.copyWith(color: fontColor),
        ),
      ),
    );
  }
}
