import 'package:flutter/material.dart';

Color hexStringToColors(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF$hexColor";
  }
  return Color(int.parse(hexColor, radix: 16));
}

class AppColors {
  static Map theme = themes["theme1"];

  static Map themes = {
    "theme1": {
      "backgroundColor": hexStringToColors("#F5F5F7"),
      "primaryColor": hexStringToColors("#A65899"),
      "secondaryColor": hexStringToColors("#757575"),
      "textColor": hexStringToColors("#212121"),
      "cardColor": hexStringToColors("#FFFFFF"),
    },
  };
}
