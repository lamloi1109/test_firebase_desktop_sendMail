import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:test_firebase_desktop/provider/storage.dart';

// ignore: must_be_immutable
class NewRecipient extends StatefulWidget {
  NewRecipient({Key? key, this.data = const {}, this.index = 0})
      : super(key: key);

  Map data;
  int index;
  // ignore: no_logic_in_create_state
  @override
  State<NewRecipient> createState() => _NewRecipientState(data, index);
}

class _NewRecipientState extends State<NewRecipient> {
  late Map data;
  final TextEditingController _recipient = TextEditingController();
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _body = TextEditingController();
  final TextEditingController _name = TextEditingController();
  List<PlatformFile> attachments = [];
  List<String> attachmentPath = [];

  bool isEdit = false;
  int index;
  _NewRecipientState(this.data, this.index);

  @override
  void dispose() {
    super.dispose();
    _recipient.dispose();
    _subject.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (data['recipient'] != null) {
      setState(() {
        _recipient.text = data['recipient'];
        _subject.text = data['subject'];
        _body.text = data['body'];
        attachments = data['attachments'];
        attachmentPath = data['attachmentPath'];
        _name.text = data['name'];
        isEdit = true;
      });
    }
  }

  saveRecipient() {
    if (_recipient.text.isEmpty ||
        _body.text.isEmpty ||
        _subject.text.isEmpty ||
        _name.text.isEmpty) {
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Missing information'),
            content: const Text('Please fill in all fields'),
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
    }
    bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(_recipient.text);
    if (!emailValid) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Invalid Email'),
            content: const Text('Please enter a valid email address'),
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

    final Map<String, dynamic> recipient = {
      'recipient': _recipient.text,
      'subject': _subject.text,
      'body': 'Dear ${_name.text},\n${_body.text}',
      'attachments': attachments,
      'attachmentPath': attachmentPath,
      'name': _name.text,
    };

    final mailList = Provider.of<StorageProvider>(context, listen: false).mails;
    if (isEdit) {
      mailList[index] = recipient;
      context.read<StorageProvider>().updateMail(mailList);
    } else {
      final newMailList = [...mailList, recipient];
      context.read<StorageProvider>().updateMail(newMailList);
    }
    setState(() {
      isEdit = false;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Email Sender'), actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: saveRecipient,
          )
        ]),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            // height:MediaQuery.of(context).size.height*1,
            width: MediaQuery.of(context).size.width * 1,
            padding: const EdgeInsets.all(5),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _recipient,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Recipient',
                          hintText: 'example@gmail.com',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _name,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: 'Recipient\'s name',
                          hintText: 'Name of the recipient',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _subject,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          hintText: 'Title of your email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _body,
                        minLines:
                            6, // any number you need (It works as the rows for the textarea)
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        decoration: const InputDecoration(
                          labelText: 'Content of your email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Click on the button to attach a file'),
                          const SizedBox(height: 5),
                          ElevatedButton(
                            onPressed: () async {
                              FilePickerResult? result =
                                  await FilePicker.platform.pickFiles();
                              if (result == null) return;
                              PlatformFile file = result.files.first;
                              setState(() {
                                attachments.add(file);
                                attachmentPath.add(file.path.toString());
                              });
                            },
                            child: const Text('Pick a file'),
                          ),
                          const SizedBox(height: 10),
                          attachments.isEmpty
                              ? const SizedBox(height: 0)
                              : Container(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                      const Text(
                                        'Attachment files',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      for (var i = 0;
                                          i < attachments.length;
                                          i++)
                                        Row(children: <Widget>[
                                          Expanded(
                                            child: Text(
                                              attachments[i].name,
                                              softWrap: false,
                                              overflow: TextOverflow.fade,
                                            ),
                                          ),
                                          IconButton(
                                              icon: const Icon(
                                                  Icons.remove_circle,
                                                  color: Colors.red),
                                              onPressed: () {
                                                setState(() {
                                                  attachments.removeAt(i);
                                                });
                                              })
                                        ])
                                    ]))
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
