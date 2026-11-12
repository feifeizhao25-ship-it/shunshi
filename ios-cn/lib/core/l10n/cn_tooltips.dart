import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 国内包的系统控件提示。
///
/// 未接 flutter_localizations 时，AppBar 返回键和菜单按钮会读英文
/// Material 文案（Back / Show menu）。这里只改这两句，其余仍用英文默认。
class CnMaterialLocalizations extends DefaultMaterialLocalizations {
  const CnMaterialLocalizations();

  @override
  String get backButtonTooltip => '返回';

  @override
  String get showMenuTooltip => '打开菜单';
}

class CnMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const CnMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return SynchronousFuture<MaterialLocalizations>(const CnMaterialLocalizations());
  }

  @override
  bool shouldReload(CnMaterialLocalizationsDelegate old) => false;
}

const List<LocalizationsDelegate<dynamic>> cnLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  CnMaterialLocalizationsDelegate(),
  DefaultWidgetsLocalizations.delegate,
  DefaultCupertinoLocalizations.delegate,
];
