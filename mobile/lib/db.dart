import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'templates/PointData.dart';

class DB {
  static final Random _random = Random();

  // Функция для генерации случайного цвета (может использоваться при необходимости)
  static Color _randomColor() {
    return Color(0xFF000000 | _random.nextInt(0xFFFFFF));
  }


  static List<PointData> points = [];

  // Получение списка точек
  static List<PointData> getPoints() => points;

  static Future<void> fetchPoints() async {
    const String url = "http://127.0.0.1:5000/points";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<PointData> fetchedPoints = data.map((point) {
          double x = (point["x"] is int) ? (point["x"].toDouble()) : point["x"];
          double y = (point["y"] is int) ? (point["y"].toDouble()) : point["y"];
          double z = (point["z"] is int) ? (point["z"].toDouble()) : point["z"];
          // Парсинг цвета из строки вида "#rrggbb"
          String colorString = point["color"];
          Color color = Color(int.parse("0xFF" + colorString.substring(1)));
          String articleTitle = point["articleTitle"];
          return PointData(
            x: x,
            y: y,
            z: z,
            color: color,
            articleTitle: articleTitle,
          );
        }).toList();
        setPoints(fetchedPoints);
      } else {
        throw Exception("Ошибка сервера: ${response.statusCode}");
      }
    } catch (e) {
      print("Ошибка при загрузке точек: $e");
      rethrow; // Пробрасываем исключение для обработки в UI
    }
  }
  // Не забудьте заменить URL на актуальный адрес вашего сервера.


  // Остальные методы остаются без изменений

  static void setPoints(List<PointData> newPoints) {
    points = newPoints;
  }

  static void updateAllColors(Color newColor) {
    points = points.map((point) {
      return PointData(
        x: point.x,
        y: point.y,
        z: point.z,
        color: newColor,
        articleTitle: point.articleTitle,
      );
    }).toList();
  }

  static void addPoint(PointData point) {
    points.add(point);
  }

  static void updatePoint(int index, PointData point) {
    if (index >= 0 && index < points.length) {
      points[index] = point;
    }
  }

  static void removePoint(int index) {
    if (index >= 0 && index < points.length) {
      points.removeAt(index);
    }
  }
}
