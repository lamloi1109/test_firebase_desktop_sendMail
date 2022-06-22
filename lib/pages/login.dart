import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:desktop_webview_auth/desktop_webview_auth.dart';
import 'package:desktop_webview_auth/google.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:test_firebase_desktop/pages/recipient_list.dart';
import 'package:test_firebase_desktop/provider/userProvider.dart';

import '../models/user.dart';

typedef SignInCallback = Future<void> Function();
const String apiKey = 'AIzaSyB-gl1XRf73KMR5ARpNO1I5WiY0ajoXWWQ';
const GOOGLE_CLIENT_ID =
    '139062472676-hhdfu3rutrml40vv72tghone9i2b8kvf.apps.googleusercontent.com';
const REDIRECT_URI =
    'https://testfirebase-13821.firebaseapp.com/__/auth/handler';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  SignInCallback signInWithArgs(BuildContext context, ProviderArgs args) =>
      () async {
        final result = await DesktopWebviewAuth.signIn(args);
        String? accessToken = result?.accessToken;
        String? idToken = result?.idToken;
        if (result != null) {
          final AuthCredential credential = GoogleAuthProvider.credential(
              accessToken: result.accessToken, idToken: result.idToken);
          await FirebaseAuth.instance.signInWithCredential(credential);
        }
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final email = user.email;
          final userModel = UserModel(email.toString(), accessToken.toString());
          Provider.of<UserProvider>(context, listen: false).setUser = userModel;
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const RecipientList()));
        }
      };
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) {
          final buttons = [
            ElevatedButton(
              onPressed: signInWithArgs(
                context,
                GoogleSignInArgs(
                  clientId: GOOGLE_CLIENT_ID,
                  redirectUri: REDIRECT_URI,
                  scope: 'https://www.googleapis.com/auth/userinfo.email '
                      'https://mail.google.com',
                ),
              ),
              child: const Text('Sign in with Google'),
            ),
          ];

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: ListView.separated(
                itemCount: buttons.length,
                shrinkWrap: true,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  return buttons[index];
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
