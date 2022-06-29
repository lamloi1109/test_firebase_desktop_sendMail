import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:provider/provider.dart';
import 'package:test_firebase_desktop/models/user.dart';
import 'package:test_firebase_desktop/provider/userProvider.dart';
import '../provider/storage.dart';
import 'package:path/path.dart' as p;

import '../widgets/row.dart';

class RecipientList extends StatefulWidget {
  const RecipientList({Key? key}) : super(key: key);

  @override
  State<RecipientList> createState() => _RecipientListState();
}

class _RecipientListState extends State<RecipientList> {
  final Set<Uri> files = {};
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

  handleSend(user) {
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
      sendMail(
          accesstoken: user.accessToken, email: user.email, messages: mails);
    }
    // print(mails);
  }

  @override
  Widget build(BuildContext context) {
    UserModel user = Provider.of<UserProvider>(context, listen: false).getUser;
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
                handleSend(user);
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
                    await FilePicker.platform.pickFiles();
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
                    if (excel.tables[table]!.rows[1][0] != 'lanAKAunicornL') {
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
                    } else if (excel.tables[table]!.rows[0].length != 6 ||
                        excel.tables[table]!.rows[0][1] != 'name' ||
                        excel.tables[table]!.rows[0][2] != 'subject' ||
                        excel.tables[table]!.rows[0][3] != 'salutation' ||
                        excel.tables[table]!.rows[0][4] != 'content' ||
                        excel.tables[table]!.rows[0][5] != 'signature') {
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
                        'toEmails': [],
                        'ccEmails': [],
                        'name': row[1],
                        'subject': row[2],
                        'salutation': row[3],
                        'content': row[4],
                        'signature': row[5],
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
                            overflow: TextOverflow.ellipsis,
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
