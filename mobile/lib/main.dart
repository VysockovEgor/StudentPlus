// main.dart
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:rive_animation/screens/entryPoint/components/menu_btn.dart';
import 'package:rive_animation/screens/entryPoint/entry_point.dart';

final GlobalKey<EntryPointState> entryPointKey = GlobalKey<EntryPointState>();


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudentPlus',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF202020),
        primarySwatch: Colors.blue,
        fontFamily: "Intel",
      ),
      home: EntryPoint(key: entryPointKey),
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            Positioned(
              left: 16,
              top: 16,
              child: MenuBtn(
                press: () {
                  entryPointKey.currentState?.toggleSidebar();
                },
                riveOnInit: (artboard) {
                  final controller = StateMachineController.fromArtboard(
                    artboard,
                    "State Machine",
                  );
                  artboard.addController(controller!);
                  entryPointKey.currentState?.isMenuOpenInput =
                  controller.findInput<bool>("isOpen") as SMIBool;
                  entryPointKey.currentState?.isMenuOpenInput.value = true;
                },
              ),
            ),
          ],
        );
      },
    );

  }
}

const defaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  borderSide: BorderSide(
    color: Color(0xFFDEE3F2),
    width: 1,
  ),
);
