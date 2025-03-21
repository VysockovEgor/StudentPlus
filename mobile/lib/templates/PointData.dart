// PointData.dart
import 'package:flutter/material.dart';

class PointData {
  final double x;
  final double y;
  final double z;
  final Color color;
  final String articleTitle; // новое поле

  PointData({
    required this.x,
    required this.y,
    required this.z,
    required this.color,
    required this.articleTitle,
  });
}
