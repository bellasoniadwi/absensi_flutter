import 'package:flutter/material.dart';

const kPrimaryColor = Color(0xff6849ef);
const kPrimaryLight = Color(0xff8a72f1);

hexStringToColor(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF" + hexColor;
  }
  return Color(int.parse(hexColor, radix: 16));
}
