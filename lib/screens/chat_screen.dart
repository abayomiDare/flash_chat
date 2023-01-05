import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  static String ID = "chat_screen";
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _fireStore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final msgTextController = TextEditingController();

  late String messageText;
  late User user;

  void getCurrentUSer() {
    final loggedInUser = _auth.currentUser;

    if (loggedInUser != null) {
      setState(() {
        user = loggedInUser;
      });
      print(user.email);
    }
  }

  @override
  void initState() {
    getCurrentUSer();
    super.initState();
  }

  // void getMessages() async {
  //   final messages = await _fireStore.collection('messages').get();
  //   for (var message in messages.docs) {
  //     print(message.data());
  //   }
  // }
  // CollectionReference<Map<String, dynamic>> getDataStream() {
  //   return _fireStore.collection('messages');
  // }

  // void getMessagesStream() {
  //   CollectionReference msgCollection = _fireStore.collection('messages');
  //   msgCollection.snapshots().listen((event) {
  //     for (var message in event.docs) {
  //       print(message.data());
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    print('kick of to print user email');
    print(user.email);
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                // getMessagesStream();
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: const Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(
              fireStore: _fireStore,
              currentUser: user.email,
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: msgTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      msgTextController.clear();
                      _fireStore.collection('messages').add({
                        'text': messageText,
                        'sender': user.email,
                      });
                      //Implement send functionality.
                    },
                    child: const Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  MessageStream(
      {Key? key, required FirebaseFirestore fireStore, this.currentUser})
      : _fireStore = fireStore,
        super(key: key);

  final FirebaseFirestore _fireStore;
  var currentUser;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fireStore.collection('messages').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const CircularProgressIndicator(
            backgroundColor: Colors.lightBlueAccent,
          );
        }
        final messages = snapshot.data?.docs.reversed;
        List<MessageBubble> msgWidgets = [];
        for (var msg in messages!) {
          final msgText = msg.get('text');
          final msgSender = msg.get('sender');

          msgWidgets.add(
            MessageBubble(
                sender: msgSender,
                text: msgText,
                isMe: currentUser == msgSender ? true : false),
          );
        }
        return Expanded(
          child: ListView(
              reverse: true,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              children: msgWidgets),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({required this.sender, required this.text, required this.isMe});
  String sender;
  String text;
  bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: const TextStyle(fontSize: 12.0, color: Colors.black54),
          ),
          Material(
            elevation: 5.0,
            borderRadius: isMe
                ? const BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0))
                : const BorderRadius.only(
                    topRight: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0)),
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Text(
                text,
                style: TextStyle(
                    fontSize: 15.0, color: isMe ? Colors.white : Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
