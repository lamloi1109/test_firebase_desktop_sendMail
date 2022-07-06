import 'package:flutter/cupertino.dart';
import 'package:test_firebase_desktop/models/zimbraUser.dart';

class zimbraUserProvider extends ChangeNotifier {
  zimbraUserModel _user;
  zimbraUserProvider(this._user);
  set setUser(user) {
    _user = user;
    notifyListeners();
  }

  zimbraUserModel get getUser => _user;
}
