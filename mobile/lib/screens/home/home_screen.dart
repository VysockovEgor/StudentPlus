// home_page.dart
import 'package:flutter/material.dart';
import '../../templates/Graph.dart';
import 'main_content.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Фоновое изображение, заполняющее весь экран
          Positioned.fill(
            child: Image.asset(
              'icons/background.png', // укажите путь к вашему изображению
              fit: BoxFit.cover,
            ),
          ),
          // Фон с графом, располагается поверх фонового изображения
          const Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: GraphView(),
            ),
          ),
          // «Ручка», выглядывающая снизу
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 800),
                    opaque: false,
                    pageBuilder: (context, animation, secondaryAnimation) =>
                    const SlideUpPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      const begin = Offset(0.0, 1.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;
                      final tween = Tween(begin: begin, end: end)
                          .chain(CurveTween(curve: curve));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
