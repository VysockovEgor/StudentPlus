// Flutter web plugin registrant file.
//
// Generated file. Do not edit.
//

// @dart = 2.13
// ignore_for_file: type=lint

import 'package:file_picker/_internal/file_picker_web.dart';
import 'package:flutter_inappwebview_web/web/main.dart';
import 'package:flutter_keyboard_visibility_temp_fork/flutter_keyboard_visibility_web.dart';
import 'package:flutter_keyboard_visibility_web/flutter_keyboard_visibility_web.dart';
import 'package:pointer_interceptor_web/pointer_interceptor_web.dart';
import 'package:quill_native_bridge_web/quill_native_bridge_web.dart';
import 'package:rive_common/rive_web.dart';
import 'package:url_launcher_web/url_launcher_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins([final Registrar? pluginRegistrar]) {
  final Registrar registrar = pluginRegistrar ?? webPluginRegistrar;
  FilePickerWeb.registerWith(registrar);
  InAppWebViewFlutterPlugin.registerWith(registrar);
  FlutterKeyboardVisibilityTempForkWeb.registerWith(registrar);
  FlutterKeyboardVisibilityPlugin.registerWith(registrar);
  PointerInterceptorWeb.registerWith(registrar);
  QuillNativeBridgeWeb.registerWith(registrar);
  RivePlugin.registerWith(registrar);
  UrlLauncherPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}
