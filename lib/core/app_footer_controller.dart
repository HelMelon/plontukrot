import 'package:flutter/foundation.dart';

/// Controls whether the global pinned [AppFooter] is shown.
class AppFooterController extends ChangeNotifier {
  AppFooterController._();

  static final AppFooterController instance = AppFooterController._();

  bool _visible = false;

  bool get visible => _visible;

  void setVisible(bool value) {
    if (_visible == value) return;
    _visible = value;
    notifyListeners();
  }
}
