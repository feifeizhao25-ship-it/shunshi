// Flutter web plugin registrant file.
//
// Generated file. Do not edit.
//

// @dart = 2.13
// ignore_for_file: type=lint

import 'package:audioplayers_web/audioplayers_web.dart';
import 'package:connectivity_plus/src/connectivity_plus_web.dart';
import 'package:flutter_secure_storage_web/flutter_secure_storage_web.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart';
import 'package:permission_handler_html/permission_handler_html.dart';
import 'package:record_web/record_web.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';
import 'package:sign_in_with_apple_web/sign_in_with_apple_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins([final Registrar? pluginRegistrar]) {
  final Registrar registrar = pluginRegistrar ?? webPluginRegistrar;
  AudioplayersPlugin.registerWith(registrar);
  ConnectivityPlusWebPlugin.registerWith(registrar);
  FlutterSecureStorageWeb.registerWith(registrar);
  GoogleSignInPlugin.registerWith(registrar);
  ImagePickerPlugin.registerWith(registrar);
  WebPermissionHandler.registerWith(registrar);
  RecordPluginWeb.registerWith(registrar);
  SharedPreferencesPlugin.registerWith(registrar);
  SignInWithApplePlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}
