import 'package:flutter/material.dart';
import 'package:test_firebase_desktop/models/zimbraUser.dart';
import 'package:test_firebase_desktop/pages/new_recipient.dart';
import 'package:test_firebase_desktop/pages/recipient_list.dart';
import 'package:test_firebase_desktop/provider/storage.dart';
import 'package:test_firebase_desktop/provider/userProvider.dart';
import 'package:test_firebase_desktop/provider/zimbraUserProvider.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test_firebase_desktop/pages/login.dart';
import 'package:provider/provider.dart';
import 'package:test_firebase_desktop/models/user.dart';

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (BuildContext context) {
          return StorageProvider();
        }),
        ChangeNotifierProvider(create: (BuildContext context) {
          return UserProvider(UserModel("", ""));
        }),
        ChangeNotifierProvider(create: (BuildContext context) {
          return zimbraUserProvider(zimbraUserModel("", "", ""));
        }),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Send Email',
        theme: ThemeData(
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              padding: MaterialStateProperty.all(const EdgeInsets.all(20)),
            ),
          ),
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/login',
        routes: {
          '/': (context) => const RecipientList(),
          '/recipient': (context) => NewRecipient(),
          '/login': (context) => const Login(),
        },
      ),
    );
  }
}
