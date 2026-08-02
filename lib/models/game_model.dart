import 'package:flutter/material.dart';

class GameModel {
  final String name;
  final String imagePath;
  final Widget page;
  final Color accentColor;

  GameModel(this.name, this.imagePath, this.page, {required this.accentColor});
}