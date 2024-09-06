import 'package:flutter/material.dart';
import "../theme/theme.dart";

class MyTextField extends StatelessWidget {
  const MyTextField({
    Key? key,
    required this.hintText,
    required this.inputType,
    this.fillColor,
    this.onChanged,
    this.controller,
  }) : super(key: key);

  final String hintText;
  final TextInputType inputType;
  final Color? fillColor;
  final Function(String)? onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    // Detect the current theme and set the fill color accordingly
    final Color backgroundColor = fillColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? kBackgroundColor
            : Colors.grey.shade200);

    // Set text color based on theme
    final Color textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : kBackgroundColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        style: kBodyText.copyWith(color: textColor),
        keyboardType: inputType,
        textInputAction: TextInputAction.next,
        onChanged: onChanged,
        decoration: InputDecoration(
          filled: true,
          fillColor: backgroundColor,
          contentPadding: EdgeInsets.all(20),
          hintText: hintText,
          hintStyle: kBodyText.copyWith(color: Colors.grey),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.grey,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.white,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
