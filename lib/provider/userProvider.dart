import 'package:flutter/cupertino.dart';
import 'package:test_firebase_desktop/models/user.dart';

class UserProvider extends ChangeNotifier {
  UserModel _user;
  UserProvider(this._user);
  set setUser(user) {
    _user = user;
    notifyListeners();
  }

  UserModel get getUser => _user;
}
