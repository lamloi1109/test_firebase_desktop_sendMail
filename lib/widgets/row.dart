import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class InputRow extends StatefulWidget {
  InputRow({
    Key? key,
    required this.mail,
    required this.index,
    required this.removeRecipient,
    required this.mails,
    required this.addNewRecipient,
    required this.updateRecipient,
  }) : super(key: key);

  int index;
  Function removeRecipient;
  List mails;
  Map<String, dynamic> mail;
  Function addNewRecipient;
  Function updateRecipient;

  @override
  State<InputRow> createState() => _InputRowState(
      index, removeRecipient, mails, addNewRecipient, updateRecipient, mail);
}

class _InputRowState extends State<InputRow> {
  final TextEditingController _torecipient = TextEditingController();
  final TextEditingController _ccrecipient = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _salutation = TextEditingController();
  final TextEditingController _body = TextEditingController();
  final TextEditingController _link = TextEditingController();
  final TextEditingController _signature = TextEditingController();

  List<PlatformFile> attachments = [];
  List attachmentPath = [];
  List mails;
  List<String> links = [];
  List<String> toEmails = [];
  List<String> ccEmails = [];
  late Map<String, dynamic> mail = {
    'toEmails': mail['toEmails'],
    'ccEmails': mail['ccEmails'],
    'name': mail['name'],
    'subject': mail['subject'],
    'salutation': mail['salutation'],
    'content': mail['content'],
    'signature': mail['signature'],
    'attachments': mail['attachments'],
    'attachmentPath': mail['attachmentPath'],
  };

  Function removeRecipient;
  Function addNewRecipient;
  Function updateRecipient;

  int index;
  bool isFinished = false;

  final titles = ['Name', 'Subject', 'Salutation', 'Content', 'Signature'];

  _InputRowState(
    this.index,
    this.removeRecipient,
    this.mails,
    this.addNewRecipient,
    this.updateRecipient,
    this.mail,
  );

  @override
  void initState() {
    super.initState();
    setState(() {
      _name.text = mail['name'];
      _subject.text = mail['subject'];
      _salutation.text = mail['salutation'];
      _body.text = mail['content'];
      _signature.text = mail['signature'];
    });
  }

  @override
  void dispose() {
    super.dispose();
    _ccrecipient.dispose();
    _torecipient.dispose();
    _subject.dispose();
    _body.dispose();
    _salutation.dispose();
    _name.dispose();
    _signature.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        default:
          return 1;
      }
    }

    TextEditingController checkForType(String value) {
      switch (value) {
        case 'Name':
          return _name;
        case 'Subject':
          return _subject;
        case 'Salutation':
          return _salutation;
        case 'Content':
          return _body;
        case 'Signature':
          return _signature;
        default:
          return _body;
      }
    }

    checkForNewLine(value) {
      if (mails.length > 1 &&
          !mails.every((element) =>
              element['toEmails'].length > 0 &&
              element['name'].isNotEmpty &&
              element['signature'].isNotEmpty &&
              element['subject'].isNotEmpty &&
              element['content'].isNotEmpty)) {
        setState(() {
          isFinished = false;
        });
      }

      if (mails.length == 1 &&
          isFinished &&
          ((ccEmails.isEmpty && toEmails.isEmpty) ||
              _name.text.isEmpty ||
              _subject.text.isEmpty ||
              _salutation.text.isEmpty ||
              _body.text.isEmpty ||
              _signature.text.isEmpty)) {
        setState(() {
          isFinished = false;
        });
      }

      if (!isFinished &&
          mails.every((element) =>
              element['toEmails'].length > 0 &&
              element['name'].isNotEmpty &&
              element['signature'].isNotEmpty &&
              element['subject'].isNotEmpty &&
              element['content'].isNotEmpty)) {
        addNewRecipient();
        setState(() {
          isFinished = true;
        });
      }

      final newUpdatedRecipient = {
        'ccEmails': ccEmails,
        'toEmails': toEmails,
        'name': _name.text,
        'subject': _subject.text,
        'salutation': _salutation.text,
        'content': _body.text,
        'signature': _signature.text,
        'attachments': attachments,
        'attachmentPath': attachmentPath,
      };

      updateRecipient(newUpdatedRecipient, index);
    }

    Future checkForPath(value) async {
      try {
        final response = await http.get(
          Uri.parse('http://localhost:5000/api/check-path/$value'),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
          },
        );

        if (response.statusCode == 200) {
          print('Found!!!');
        } else {
          print('Not Found');
        }
      } catch (err) {
        print(err);
      }
    }

    return Row(
      children: [
        Flexible(
            flex: 2,
            child: Container(
              height: 128,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: SizedBox(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onSubmitted: (value) {
                                print("dsa");

                                bool correctFormat = RegExp(
                                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                    .hasMatch(value);
                                if (correctFormat) {
                                  setState(() {
                                    toEmails.add(value);
                                  });
                                  final newUpdatedRecipient = {
                                    'ccEmails': ccEmails,
                                    'toEmails': toEmails,
                                    'name': _name.text,
                                    'subject': _subject.text,
                                    'salutation': _salutation.text,
                                    'content': _body.text,
                                    'signature': _signature.text,
                                    'attachments': attachments,
                                    'attachmentPath': attachmentPath,
                                  };
                                  updateRecipient(newUpdatedRecipient, index);
                                  checkForNewLine('');
                                  return _torecipient.clear();
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text(
                                            'Invalid email detected'),
                                        content: const Text(
                                            'Please check the format of your provided email'),
                                        actions: [
                                          ElevatedButton(
                                            child: const Text('OK'),
                                            onPressed: () {
                                              return Navigator.of(context)
                                                  .pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  return;
                                }
                              },
                              keyboardType: TextInputType.text,
                              controller: _torecipient,
                              decoration: const InputDecoration(
                                labelText: 'ToEmail',
                                hintText: 'example@gmail.com:',
                                isDense: true,
                                contentPadding: EdgeInsets.all(10),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      toEmails.isEmpty
                          ? const SizedBox(height: 0)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  for (var i = 0; i < toEmails.length; i++)
                                    Row(children: <Widget>[
                                      Expanded(
                                        child: Text(toEmails[i],
                                            softWrap: false,
                                            overflow: TextOverflow.fade),
                                      ),
                                      IconButton(
                                          icon: const Icon(Icons.remove_circle,
                                              color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              toEmails.removeAt(i);
                                            });
                                            checkForNewLine('');
                                          })
                                    ]),
                                ]),
                    ],
                  ),
                ),
              ),
            )),
        Flexible(
            flex: 2,
            child: Container(
              height: 128,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: SizedBox(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onSubmitted: (value) {
                                bool correctFormat = RegExp(
                                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                    .hasMatch(value);
                                if (correctFormat) {
                                  setState(() {
                                    ccEmails.add(value);
                                  });
                                  final newUpdatedRecipient = {
                                    'ccEmails': ccEmails,
                                    'toEmails': toEmails,
                                    'name': _name.text,
                                    'subject': _subject.text,
                                    'salutation': _salutation.text,
                                    'content': _body.text,
                                    'signature': _signature.text,
                                    'attachments': attachments,
                                    'attachmentPath': attachmentPath
                                  };
                                  updateRecipient(newUpdatedRecipient, index);
                                  checkForNewLine('');
                                  return _ccrecipient.clear();
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text(
                                            'Invalid email detected'),
                                        content: const Text(
                                            'Please check the format of your provided email'),
                                        actions: [
                                          ElevatedButton(
                                            child: const Text('OK'),
                                            onPressed: () {
                                              return Navigator.of(context)
                                                  .pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  return;
                                }
                              },
                              keyboardType: TextInputType.text,
                              controller: _ccrecipient,
                              decoration: const InputDecoration(
                                labelText: 'CcEmail',
                                hintText: 'example@gmail.com:',
                                isDense: true,
                                contentPadding: EdgeInsets.all(10),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ccEmails.isEmpty
                          ? const SizedBox(height: 0)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  for (var i = 0; i < ccEmails.length; i++)
                                    Row(children: <Widget>[
                                      Expanded(
                                        child: Text(ccEmails[i],
                                            softWrap: false,
                                            overflow: TextOverflow.fade),
                                      ),
                                      IconButton(
                                          icon: const Icon(Icons.remove_circle,
                                              color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              ccEmails.removeAt(i);
                                            });
                                            checkForNewLine('');
                                          })
                                    ]),
                                ]),
                    ],
                  ),
                ),
              ),
            )),
        for (var i = 0; i < titles.length; i++)
          Flexible(
            flex: checkForContent(titles[i]),
            child: Container(
              margin: const EdgeInsets.all(1),
              child: TextField(
                minLines:
                    5, // any number you need (It works as the rows for the textarea)
                maxLines: 5,
                onChanged: (value) => checkForNewLine(value),
                controller: checkForType(titles[i]),
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(width: 1, color: Colors.grey),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(width: 1, color: Colors.blue),
                      borderRadius: BorderRadius.circular(5),
                    )),
              ),
            ),
          ),
        Flexible(
            flex: 3,
            child: Container(
              height: 128,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: SizedBox(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
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
                              final newUpdatedRecipient = {
                                'ccEmails': ccEmails,
                                'toEmails': toEmails,
                                'name': _name.text,
                                'subject': _subject.text,
                                'salutation': _salutation.text,
                                'content': _body.text,
                                'signature': _signature.text,
                                'attachments': attachments,
                                'attachmentPath': attachmentPath
                              };
                              updateRecipient(newUpdatedRecipient, index);
                            },
                            child: const Text('Pick a file'),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      attachments.isEmpty
                          ? const SizedBox(height: 0)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  for (var i = 0; i < attachments.length; i++)
                                    Row(children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          attachments[i].name,
                                          softWrap: false,
                                          overflow: TextOverflow.fade,
                                        ),
                                      ),
                                      IconButton(
                                          icon: const Icon(Icons.remove_circle,
                                              color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              attachments.removeAt(i);
                                              attachmentPath.removeAt(i);
                                            });
                                          })
                                    ]),
                                ])
                    ],
                  ),
                ),
              ),
            )),
        Flexible(
            flex: 3,
            child: Container(
              height: 128,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: SizedBox(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.multiline,
                              controller: _link,
                              decoration: const InputDecoration(
                                labelText: 'Link of the file',
                                hintText: 'C:',
                                isDense: true,
                                contentPadding: EdgeInsets.all(10),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          ElevatedButton(
                            onPressed: () => checkForPath(_link.text),
                            child: const Text('Find'),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      links.isEmpty
                          ? const SizedBox(height: 0)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  for (var i = 0; i < links.length; i++)
                                    Row(children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          links[i],
                                          softWrap: false,
                                          overflow: TextOverflow.fade,
                                        ),
                                      ),
                                      IconButton(
                                          icon: const Icon(Icons.remove_circle,
                                              color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              links.removeAt(i);
                                            });
                                          })
                                    ]),
                                ])
                    ],
                  ),
                ),
              ),
            )),
        Flexible(
            flex: 1,
            child: Container(
              height: 128,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: Center(
                  child: mails.length > 1
                      ? IconButton(
                          icon: const Icon(Icons.delete_outlined,
                              size: 25, color: Colors.red),
                          onPressed: () {
                            removeRecipient(index);
                          })
                      : const SizedBox(height: 0)),
            ))
      ],
    );
  }
}
