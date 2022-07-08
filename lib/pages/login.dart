import 'dart:convert';

import 'package:client_cookie/client_cookie.dart';
import 'package:desktop_webview_auth/google.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:desktop_webview_auth/desktop_webview_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:form_validation/form_validation.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:test_firebase_desktop/models/zimbraUser.dart';
import 'dart:async';
import 'package:test_firebase_desktop/pages/recipient_list.dart';
import 'package:test_firebase_desktop/provider/userProvider.dart';
import 'package:test_firebase_desktop/provider/zimbraUserProvider.dart';
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
  String email = "";
  String emailError = "";
  String passwd = "";
  String passwdError = "";
  bool _loading = false;
  String AuthToken = "";
  late int statusCode;
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
  _AuthPostRequest() async {
    try {
      String url = 'https://mail.seacorp.vn/service/soap';
      Map<String, String> headers = {"Content-type": "application/json"};
      var body = json.encode({
        "Header": {
          "context": {
            "_jsns": "urn:zimbra",
            "userAgent": {"name": "curl", "version": "9.0.0"}
          }
        },
        "Body": {
          "AuthRequest": {
            "_jsns": "urn:zimbraAccount",
            "account": {"_content": email, "by": "name"},
            "password": passwd
          }
        }
      });
      Response response =
          await post(Uri.parse(url), headers: headers, body: body);
      String bodyRsp = response.body;
      final bodyRs = json.decode(response.body);
      var statusCode = response.statusCode;
      if (response.statusCode == 200) {
        if (bodyRs['Body'] == null) {
          print("err");
        } else {
          AuthToken =
              bodyRs['Body']['AuthResponse']['authToken'][0]['_content'];
          final cookie = ClientCookie.fromMap(
              'ZM_AUTH_TOKEN',
              AuthToken,
              DateTime.now(),
              {'domain': 'https://mail.seacorp.vn', 'path': '/service/soap'});
          final zimbraUser = zimbraUserModel(email, passwd, AuthToken);
          Provider.of<zimbraUserProvider>(context, listen: false).setUser =
              zimbraUser;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Sucessful')),
          );
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const RecipientList()));
        }
      } else {
        String errMsg = bodyRs['Body']['Fault']['Reason']['Text'].toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg)),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  final _formKey = GlobalKey<FormState>();

  void _onSubmit() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 3));
    _loading = false;
    if (mounted == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 750.0) {
      return Scaffold(
          appBar: null,
          backgroundColor: Colors.white,
          body: Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        stops: [0.4, 0.8],
                        colors: [
                          Color.fromARGB(255, 199, 243, 241),
                          Color.fromARGB(255, 112, 231, 235)
                        ],
                      )),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    children: <Widget>[
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 25),
                      //   child: SvgPicture.asset(
                      //     'assets/images/bg.svg',
                      //     width: MediaQuery.of(context).size.width * 0.4,
                      //     height: MediaQuery.of(context).size.height * 0.4,
                      //     fit: BoxFit.contain,
                      //   ),
                      // ),
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: Container(
                            alignment: Alignment.center,
                            child: Form(
                              key: _formKey,
                              child: ListView(
                                shrinkWrap: true,
                                children: [
                                  Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.only(left: 20),
                                    child: const Text(
                                      'LOGIN PAGE',
                                      style: TextStyle(
                                          fontSize: 35,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 15),
                                          child: TextFormField(
                                            validator: (value) {
                                              var validator = Validator(
                                                validators: [
                                                  RequiredValidator(),
                                                  EmailValidator(),
                                                ],
                                              );

                                              return validator.validate(
                                                context: context,
                                                label: 'Email',
                                                value: value,
                                              );
                                            },
                                            onChanged: (value) {
                                              setState(() {
                                                email = value;
                                              });
                                            },
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            decoration: const InputDecoration(
                                                labelText: 'Email',
                                                errorBorder: InputBorder.none,
                                                border: InputBorder.none),
                                          ),
                                        )),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Text(emailError),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 15),
                                          child: TextFormField(
                                            validator: (value) {
                                              var validator = Validator(
                                                validators: [
                                                  RequiredValidator(),
                                                ],
                                              );

                                              return validator.validate(
                                                context: context,
                                                label: 'Password',
                                                value: value,
                                              );
                                            },
                                            onChanged: (value) {
                                              setState(() {
                                                passwd = value;
                                              });
                                            },
                                            obscureText: true,
                                            decoration: const InputDecoration(
                                              labelText: 'Password',
                                              errorBorder: InputBorder.none,
                                              border: InputBorder.none,
                                            ),
                                          ),
                                        )),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Text(passwdError),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        primary: const Color.fromARGB(
                                            255, 73, 182, 185),
                                      ),
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          _AuthPostRequest();
                                        }
                                      },
                                      child: const Text(
                                        'Login With Zimbra',
                                        style: TextStyle(fontSize: 20),
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Row(children: const <Widget>[
                                    Expanded(
                                        child: Divider(
                                      indent: 20.0,
                                      endIndent: 10.0,
                                      thickness: 1,
                                    )),
                                    Text(
                                      "Or continue with",
                                      style: TextStyle(color: Colors.blueGrey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Expanded(
                                        child: Divider(
                                      indent: 20.0,
                                      endIndent: 10.0,
                                      thickness: 1,
                                    )),
                                  ]),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          primary: const Color.fromARGB(
                                              255, 73, 182, 185),
                                          fixedSize: const Size(100, 50)),
                                      onPressed: signInWithArgs(
                                        context,
                                        GoogleSignInArgs(
                                          clientId: GOOGLE_CLIENT_ID,
                                          redirectUri: REDIRECT_URI,
                                          scope:
                                              'https://www.googleapis.com/auth/userinfo.email '
                                              'https://mail.google.com',
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SvgPicture.asset(
                                            'assets/images/google.svg',
                                            fit: BoxFit.cover,
                                          ),
                                          Container(
                                              padding: const EdgeInsets.only(
                                                  left: 10.0, right: 10.0),
                                              child: const Text(
                                                "Google",
                                                style: TextStyle(fontSize: 20),
                                                overflow: TextOverflow.ellipsis,
                                              )),
                                        ],
                                      )),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                )),
          ));
    } else {
      return Scaffold(
          appBar: null,
          backgroundColor: Colors.white,
          body: Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        stops: [0.4, 0.8],
                        colors: [
                          Color.fromARGB(255, 199, 243, 241),
                          Color.fromARGB(255, 112, 231, 235)
                        ],
                      )),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: SvgPicture.asset(
                          'assets/images/bg.svg',
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: MediaQuery.of(context).size.height * 0.4,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.3,
                          child: Container(
                            alignment: Alignment.center,
                            child: Form(
                              key: _formKey,
                              child: ListView(
                                shrinkWrap: true,
                                children: [
                                  Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.only(left: 20),
                                    child: const Text(
                                      'LOGIN PAGE',
                                      style: TextStyle(
                                          fontSize: 35,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 15),
                                          child: TextFormField(
                                            validator: (value) {
                                              var validator = Validator(
                                                validators: [
                                                  RequiredValidator(),
                                                  EmailValidator(),
                                                ],
                                              );

                                              return validator.validate(
                                                context: context,
                                                label: 'Email',
                                                value: value,
                                              );
                                            },
                                            onChanged: (value) {
                                              setState(() {
                                                email = value;
                                              });
                                            },
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            decoration: const InputDecoration(
                                                labelText: 'Email',
                                                errorBorder: InputBorder.none,
                                                border: InputBorder.none),
                                          ),
                                        )),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Text(emailError),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 15),
                                          child: TextFormField(
                                            validator: (value) {
                                              var validator = Validator(
                                                validators: [
                                                  RequiredValidator(),
                                                ],
                                              );

                                              return validator.validate(
                                                context: context,
                                                label: 'Password',
                                                value: value,
                                              );
                                            },
                                            onChanged: (value) {
                                              setState(() {
                                                passwd = value;
                                              });
                                            },
                                            obscureText: true,
                                            keyboardType:
                                                TextInputType.visiblePassword,
                                            decoration: const InputDecoration(
                                              labelText: 'Password',
                                              errorBorder: InputBorder.none,
                                              border: InputBorder.none,
                                            ),
                                          ),
                                        )),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Text(passwdError),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        primary: const Color.fromARGB(
                                            255, 73, 182, 185),
                                      ),
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          _AuthPostRequest();
                                        }
                                      },
                                      child: const Text(
                                        'Login With Zimbra',
                                        style: TextStyle(fontSize: 20),
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Row(children: const <Widget>[
                                    Expanded(
                                        child: Divider(
                                      indent: 20.0,
                                      endIndent: 10.0,
                                      thickness: 1,
                                    )),
                                    Text(
                                      "Or continue with",
                                      style: TextStyle(color: Colors.blueGrey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Expanded(
                                        child: Divider(
                                      indent: 20.0,
                                      endIndent: 10.0,
                                      thickness: 1,
                                    )),
                                  ]),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          primary: const Color.fromARGB(
                                              255, 73, 182, 185),
                                          fixedSize: const Size(100, 50)),
                                      onPressed: signInWithArgs(
                                        context,
                                        GoogleSignInArgs(
                                          clientId: GOOGLE_CLIENT_ID,
                                          redirectUri: REDIRECT_URI,
                                          scope:
                                              'https://www.googleapis.com/auth/userinfo.email '
                                              'https://mail.google.com',
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SvgPicture.asset(
                                            'assets/images/google.svg',
                                            fit: BoxFit.cover,
                                          ),
                                          Container(
                                              padding: const EdgeInsets.only(
                                                  left: 10.0, right: 10.0),
                                              child: const Text(
                                                "Google",
                                                style: TextStyle(fontSize: 20),
                                                overflow: TextOverflow.ellipsis,
                                              )),
                                        ],
                                      )),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                )),
          ));
    }
  }
}
