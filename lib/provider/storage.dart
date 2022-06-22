import 'package:flutter/cupertino.dart';

class StorageProvider extends ChangeNotifier {
  List<Map> _mails = [];

  List<Map> get mails => _mails;

  void updateMail(data) {
    _mails = data;
    notifyListeners();
  }
}
