import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:provider/provider.dart';
import 'package:test_firebase_desktop/models/user.dart';
import 'package:test_firebase_desktop/models/zimbraUser.dart';
import 'package:test_firebase_desktop/provider/userProvider.dart';
import 'package:test_firebase_desktop/provider/zimbraUserProvider.dart';
import '../provider/storage.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import '../widgets/row.dart';

class RecipientList extends StatefulWidget {
  const RecipientList({Key? key}) : super(key: key);

  @override
  State<RecipientList> createState() => _RecipientListState();
}

class _RecipientListState extends State<RecipientList> {
  final Set<Uri> files = {};
  List attach = [];
  String aid = "";
  Map<String, dynamic> recipient = {
    'toEmails': [],
    'ccEmails': [],
    'name': '',
    'subject': '',
    'salutation': '',
    'content': '',
    'signature': '',
    'attachments': [],
    'attachmentPath': [],
  };

  final titles = [
    'ToEmails',
    'ccEmails',
    'Name',
    'Subject',
    'Salutation',
    'Content',
    'Signature',
    'Attachments',
    'File from link',
    ''
  ];

  int checkForContent(value) {
    switch (value) {
      case 'ToEmails':
        return 2;
      case 'ccEmails':
        return 2;
      case 'Name':
        return 2;
      case 'Subject':
        return 2;
      case 'Salutation':
        return 2;
      case 'Content':
        return 3;
      case 'Signature':
        return 2;
      case 'Attachments':
        return 3;
      case 'File from link':
        return 3;
      case '':
        return 1;
      default:
        return 1;
    }
  }

  sendMail(
      {required String accesstoken,
      required String email,
      required List messages}) async {
    final smtpServer = gmailSaslXoauth2(email, accesstoken);

    for (var element in messages) {
      Iterable<Attachment> toAt(Iterable<dynamic>? attachmentPath) =>
          (attachmentPath ?? []).map((a) => FileAttachment(File(a)));

      final message = Message()
        ..from = Address(email)
        ..recipients.addAll(element['toEmails'])
        ..ccRecipients.addAll(element['ccEmails'])
        // ..bccRecipients.addAll(element.bcc)
        ..subject = element['subject']
        ..attachments.addAll(toAt(element['attachmentPath']))
        ..text = element['content'];

      try {
        final sendReport = send(message, smtpServer);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email sending...')),
        );
      } on MailerException catch (e) {
        print(e);
        for (var p in e.problems) {
          print('Problem: ${p.code}: ${p.msg}');
        }
      }
    }
  }

  _SendMailPostRequest(user, messages) async {
    String url = 'https://mail.seacorp.vn/service/soap';
    Map<String, String> headers = {"Content-type": "application/json"};
    List e = [
      {"a": user.email, "t": "f"},
    ];
    for (var element in messages) {
      // ToEmails
      if (element['toEmails'].length > 0) {
        for (var element in element['toEmails']) {
          e.add({"a": element, "t": "t"});
        }
      }
      // ccEmails
      if (element['ccEmails'].length > 0) {
        for (var element in element['ccEmails']) {
          e.add({"a": element, "t": "c"});
        }
      }
      // attachments
      if (element['attachments'].length > 0) {
        for (var element in element['attachments']) {
          _uploadFileRequest(user, element).then((value) {
            if (attach.length < element['attachments'].length) {
              print("@");

              attach.add({"aid": value.substring(1, value.length - 2)});
            }
          });
        }
      }
      print(element['attachments'].length);
      print(attach.length);
      print(attach);
      if (element['attachments'].length == attach.length) {
        var body = json.encode({
          "Header": {
            "context": {
              "userAgent": {"name": "curl", "version": "7.54.0"},
              "authTokenControl": {"voidOnExpired": true},
              "account": {"_content": user.email, "by": "name"},
              "authToken": user.Athur_TOken,
              "_jsns": "urn:zimbra"
            }
          },
          "Body": {
            "SendMsgRequest": {
              "_jsns": "urn:zimbraMail",
              "m": {
                "su": element['subject'],
                "e": e,
                "mp": [
                  {"ct": "text/plain", "content": element['content']},
                ],
                "attach": attach
              }
            }
          }
        });
        print(body);
        // var response = await post(Uri.parse(url), headers: headers, body: body);
        // String bodyRsp = response.body;
        // print(bodyRsp);
        attach.clear();
      }
    }
  }

  Future<String> _uploadFileRequest(user, file) async {
    String fileName = file.split('\\')[file.split('\\').length - 1];
    print(file.split('\\')[file.split('\\').length - 1]);
    var headers = {
      'Content-Type': 'multipart/form-data',
      'Content-Disposition': 'attachment; filename="$fileName"',
      'Cookie': 'ZM_AUTH_TOKEN="${user.Athur_TOken}"'
    };

    var url = Uri.parse('https://mail.seacorp.vn/service/upload?fmt=raw');

    http.MultipartRequest request = http.MultipartRequest("POST", url);

    http.MultipartFile multipartFile =
        await http.MultipartFile.fromPath(fileName, "$file");

    request.files.add(multipartFile);
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    final respStr = await response.stream.bytesToString();
    return respStr.split(',')[2];
  }

  late List mails = [recipient];
  void addNewRecipient() {
    setState(() {
      mails.add(recipient);
    });
  }

  // removeRecipient(index) {
  //   List messages = Provider.of<StorageProvider>(context, listen: false).mails;
  //   messages.removeAt(index);
  //   context.read<StorageProvider>().updateMail(messages);
  // }
  void removeRecipient(int index) {
    if (mails.length == 1) return;
    setState(() {
      mails.removeAt(index);
    });
  }

  void updateRecipient(data, index) {
    final currentMails = mails;
    for (int i = 0; i < currentMails.length; i++) {
      if (i != index) continue;
      currentMails[i] = data;
    }
    setState(() {
      mails = currentMails;
    });
  }

  handleSend(user, zimbraUser) {
    bool isProvidedFullInfo = mails.every((element) =>
        element['toEmails'].length > 0 &&
        element['name'].isNotEmpty &&
        element['signature'].isNotEmpty &&
        element['subject'].isNotEmpty &&
        element['content'].isNotEmpty);
    if (!isProvidedFullInfo) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Missing information'),
            content: const Text('Please fill in all required fields'),
            actions: [
              ElevatedButton(
                child: const Text('OK'),
                onPressed: () {
                  return Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      if (user.accessToken != "" && zimbraUser.Athur_TOken == "") {
        print("gmail");
        sendMail(
            accesstoken: user.accessToken, email: user.email, messages: mails);
      } else {
        print("zimbra");
        _SendMailPostRequest(zimbraUser, mails);
      }
    }
  }

  checkForCorrectEmailFormat(arr) {
    List tempArr = [...arr];
    for (var i = 0; i < tempArr.length; i++) {
      bool correctFormat = RegExp(
              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
          .hasMatch(tempArr[i]);
      if (!correctFormat) {
        tempArr.removeAt(i);
      }
    }
    return tempArr;
  }

  @override
  Widget build(BuildContext context) {
    UserModel user = Provider.of<UserProvider>(context, listen: false).getUser;
    zimbraUserModel zimbraUser =
        Provider.of<zimbraUserProvider>(context, listen: false).getUser;

    List messages = Provider.of<StorageProvider>(context, listen: false).mails;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Email'),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout_outlined),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                List messages =
                    Provider.of<StorageProvider>(context, listen: false).mails;
                messages.clear();
                context.read<StorageProvider>().updateMail(messages);
                Provider.of<UserProvider>(context, listen: false).setUser =
                    UserModel("", "");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('SignOut')),
                );
                Navigator.of(context).pop();
              }),
          IconButton(
              icon: const Icon(Icons.send_outlined),
              onPressed: () {
                handleSend(user, zimbraUser);
                // _uploadFileRequest(zimbraUser);
              })
        ],
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: <
                  Widget>[
            const Text('Import data from excel file',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles(withData: true);
                if (result == null) return;
                PlatformFile file = result.files.first;
                final extension = p.extension(file.name);
                if (extension != '.xlsx' &&
                    extension != '.xls' &&
                    extension != '.xlsm' &&
                    extension != '.xlsb') {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Wrong format'),
                        content: const Text('Please choose excel file'),
                        actions: [
                          ElevatedButton(
                            child: const Text('OK'),
                            onPressed: () {
                              return Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                  return;
                } else {
                  var bytes = file.bytes;
                  var excel = Excel.decodeBytes(bytes!);
                  for (var table in excel.tables.keys) {
                    if (excel.tables[table]!.rows[0].length != 8 ||
                        excel.tables[table]!.rows[0][1]!.value != 'name' ||
                        excel.tables[table]!.rows[0][2]!.value != 'subject' ||
                        excel.tables[table]!.rows[0][3]!.value !=
                            'salutation' ||
                        excel.tables[table]!.rows[0][4]!.value != 'content' ||
                        excel.tables[table]!.rows[0][5]!.value != 'signature' ||
                        excel.tables[table]!.rows[0][6]!.value != 'toEmails' ||
                        excel.tables[table]!.rows[0][7]!.value != 'ccEmails') {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Wrong format'),
                            content: const Text(
                                'Please choose excel file with correct format'),
                            actions: [
                              ElevatedButton(
                                child: const Text('OK'),
                                onPressed: () {
                                  return Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                      return;
                    }
                    for (var i = 0; i < excel.tables[table]!.rows.length; i++) {
                      if (i == 0) continue;
                      final row = excel.tables[table]!.rows[i];

                      Map<String, dynamic> newMail = {
                        'toEmails': row[6]?.value != null
                            ? checkForCorrectEmailFormat(
                                row[6]!.value.split(';'))
                            : [],
                        'ccEmails': row[7]?.value != null
                            ? checkForCorrectEmailFormat(
                                row[7]!.value.split(';'))
                            : [],
                        'name': row[1]!.value,
                        'subject': row[2]!.value,
                        'salutation': row[3]!.value,
                        'content': row[4]!.value,
                        'signature': row[5]!.value,
                        'attachments': [],
                      };
                      setState(() {
                        mails.add(newMail);
                      });
                    }
                  }
                }
              },
              child: const Text('Import data',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                for (var i = 0; i < titles.length; i++)
                  Expanded(
                    flex: checkForContent(titles[i]),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: i == titles.length - 1
                            ? Colors.transparent
                            : Colors.blue,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      child: Center(
                        child: Text(titles[i],
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
            for (var i = 0; i < mails.length; i++)
              InputRow(
                  index: i,
                  mail: mails[i],
                  removeRecipient: removeRecipient,
                  mails: mails,
                  addNewRecipient: addNewRecipient,
                  updateRecipient: updateRecipient)
          ]),
        ),
      ),
    );
  }
}
