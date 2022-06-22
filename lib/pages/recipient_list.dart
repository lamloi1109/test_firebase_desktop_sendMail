import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:provider/provider.dart';
import 'package:test_firebase_desktop/models/user.dart';
import 'package:test_firebase_desktop/pages/new_recipient.dart';
import 'package:test_firebase_desktop/provider/userProvider.dart';
import '../provider/storage.dart';

class RecipientList extends StatefulWidget {
  const RecipientList({Key? key}) : super(key: key);

  @override
  State<RecipientList> createState() => _RecipientListState();
}

class _RecipientListState extends State<RecipientList> {
  sendMail(
      {required String accesstoken,
      required String email,
      required List messages}) async {
    final smtpServer = gmailSaslXoauth2(email, accesstoken);
    for (var element in messages) {
      Iterable<Attachment> toAt(Iterable<String>? attachmentPath) =>
          (attachmentPath ?? []).map((a) => FileAttachment(File(a)));

      final message = Message()
        ..from = Address(email)
        ..recipients.add(element['recipient'])
        // ..ccRecipients.addAll(element.cc)
        // ..bccRecipients.addAll(element.bcc)
        ..subject = element['subject']
        ..attachments.addAll(toAt(element['attachmentPath']))
        ..text = element['body'];
      try {
        final sendReport = send(message, smtpServer);
      } on MailerException catch (e) {
        print(e);
        for (var p in e.problems) {
          print('Problem: ${p.code}: ${p.msg}');
        }
      }
    }
  }

  removeRecipient(index) {
    List messages = Provider.of<StorageProvider>(context, listen: false).mails;
    messages.removeAt(index);
    context.read<StorageProvider>().updateMail(messages);
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
                Provider.of<UserProvider>(context, listen: false).setUser =
                    UserModel("", "");
                context.read<StorageProvider>().updateMail([]);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('SignOut')),
                );
                Navigator.of(context).pop();
              }),
          IconButton(
              icon: const Icon(Icons.send_outlined),
              onPressed: () {
                sendMail(
                    accesstoken: user.accessToken,
                    email: user.email,
                    messages: messages);
              })
        ],
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: <Widget>[
          const Text('Recipient List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          for (var i = 0;
              i < context.watch<StorageProvider>().mails.length;
              i++)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: <Widget>[
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => NewRecipient(
                              data: context.watch<StorageProvider>().mails[i],
                              index: i),
                        ),
                      );
                    },
                    child: Text(
                      context.watch<StorageProvider>().mails[i]['recipient'],
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      removeRecipient(i);
                    })
              ]),
            ),
        ]),
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => NewRecipient(data: const {})));
        },
        child: const Icon(Icons.add),
      ), //
    );
  }
}
