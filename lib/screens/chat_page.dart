import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';

class ChatPage extends StatefulWidget {
  static const String id = 'chat_page';
  final String friendEmail;

  const ChatPage({super.key, required this.friendEmail});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;
  File? _imageFile;
  final Record _record = Record();
  String? _recordingPath;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      setState(() {
        this.user = user;
      });
    });
  }

  void _sendMessage({String? imageUrl, String? voiceUrl}) async {
    if ((_controller.text.isNotEmpty || imageUrl != null || voiceUrl != null) &&
        user != null) {
      DocumentSnapshot senderDoc =
          await _firestore.collection('users').doc(user!.email).get();

      String senderName = senderDoc.exists
          ? (senderDoc.data() as Map<String, dynamic>)['username'] ??
              user!.email!
          : user!.email!;
      String senderPhotoURL = senderDoc.exists
          ? (senderDoc.data() as Map<String, dynamic>)['photoURL'] ?? ''
          : '';

      _firestore.collection('messages').add({
        'text': _controller.text,
        'sender': user!.email,
        'senderName': senderName,
        'senderPhotoURL': senderPhotoURL,
        'receiver': widget.friendEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'voiceUrl': voiceUrl,
      });
      _controller.clear();
      _scrollToBottom();
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null || user == null) return;

    final ref = FirebaseStorage.instance
        .ref()
        .child('chat_images')
        .child('${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(_imageFile!);
    final imageUrl = await ref.getDownloadURL();
    _sendMessage(imageUrl: imageUrl);
  }

  Future<void> _startRecording() async {
    if (await _record.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      _recordingPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _record.start(
        path: _recordingPath,
        encoder: AudioEncoder.aacLc,
      );
      setState(() {
        _isRecording = true;
      });
    } else {
      // Handle the case where the user denied the permission.
    }
  }

  Future<void> _stopRecording() async {
    await _record.stop();
    setState(() {
      _isRecording = false;
    });
    _uploadVoice();
  }

  Future<void> _uploadVoice() async {
    if (_recordingPath == null || user == null) return;

    final ref = FirebaseStorage.instance
        .ref()
        .child('chat_voices')
        .child('${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.m4a');
    await ref.putFile(File(_recordingPath!));
    final voiceUrl = await ref.getDownloadURL();
    _sendMessage(voiceUrl: voiceUrl);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _deleteMessage(DocumentSnapshot message) async {
    await _firestore.collection('messages').doc(message.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('users')
              .doc(widget.friendEmail)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Text(widget.friendEmail);
            }
            var userDoc = snapshot.data!.data() as Map<String, dynamic>;
            return Text(userDoc['username'] ?? widget.friendEmail);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('messages')
                    .orderBy('timestamp')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs;
                  List<MessageBubble> messageBubbles = [];
                  for (var message in messages) {
                    final messageData = message.data() as Map<String, dynamic>;
                    final messageText = messageData['text'];
                    final messageSender = messageData['sender'];
                    final messageSenderName =
                        messageData['senderName'] ?? messageSender;
                    final messageSenderPhotoURL =
                        messageData['senderPhotoURL'] ?? '';
                    final messageReceiver = messageData['receiver'];
                    final messageImageUrl = messageData['imageUrl'];
                    final messageVoiceUrl = messageData['voiceUrl'];

                    if ((messageSender == user!.email &&
                            messageReceiver == widget.friendEmail) ||
                        (messageSender == widget.friendEmail &&
                            messageReceiver == user!.email)) {
                      final messageBubble = MessageBubble(
                        sender: messageSenderName,
                        text: messageText,
                        isMe: user!.email == messageSender,
                        photoURL: messageSenderPhotoURL,
                        imageUrl: messageImageUrl,
                        voiceUrl: messageVoiceUrl,
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Delete Message'),
                                content: Text(
                                    'Are you sure you want to delete this message?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _deleteMessage(message);
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );

                      messageBubbles.add(messageBubble);
                    }
                  }

                  // Scroll to bottom whenever the StreamBuilder updates
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  return ListView(
                    controller: _scrollController,
                    reverse: false,
                    children: messageBubbles,
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: _pickImage,
                  ),
                  IconButton(
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Enter your message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(10.0),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _sendMessage(),
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

class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final bool isMe;
  final String photoURL;
  final String? imageUrl;
  final String? voiceUrl;
  final VoidCallback onLongPress;

  const MessageBubble({
    required this.sender,
    required this.text,
    required this.isMe,
    required this.photoURL,
    required this.onLongPress,
    this.imageUrl,
    this.voiceUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMe)
                  CircleAvatar(
                    backgroundImage: photoURL.isNotEmpty
                        ? NetworkImage(photoURL)
                        : const NetworkImage(
                            'https://png.pngitem.com/pimgs/s/421-4212266_transparent-default-avatar-png-default-avatar-images-png.png'),
                    radius: 15,
                  ),
                const SizedBox(width: 8),
                Text(
                  sender,
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            if (imageUrl != null)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FullScreenImage(imageUrl: imageUrl!),
                    ),
                  );
                },
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: 150, // Maximum height for the thumbnail
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            if (voiceUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: VoiceMessageBubble(
                  voiceUrl: voiceUrl!,
                  isMe: isMe,
                ),
              ),
            if (voiceUrl == null && imageUrl == null)
              Material(
                borderRadius: isMe
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(30.0),
                        bottomLeft: Radius.circular(30.0),
                        bottomRight: Radius.circular(30.0),
                      )
                    : const BorderRadius.only(
                        topRight: Radius.circular(30.0),
                        bottomLeft: Radius.circular(30.0),
                        bottomRight: Radius.circular(30.0),
                      ),
                elevation: 5.0,
                color: isMe ? Colors.lightBlueAccent : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 20.0),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black54,
                      fontSize: 15.0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class VoiceMessageBubble extends StatefulWidget {
  final String voiceUrl;
  final bool isMe;

  const VoiceMessageBubble(
      {super.key, required this.voiceUrl, required this.isMe});

  @override
  VoiceMessageBubbleState createState() => VoiceMessageBubbleState();
}

class VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration();
  Duration _position = Duration();

  @override
  void initState() {
    super.initState();
    _audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() {
        _duration = d;
      });
    });
    _audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() {
        _position = p;
      });
    });
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _position = Duration();
      });
    });
  }

  void _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.voiceUrl));
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: widget.isMe ? Colors.lightBlueAccent : Colors.grey[200],
            borderRadius: BorderRadius.circular(15),
          ),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: widget.isMe ? Colors.white : Colors.black,
                ),
                onPressed: _playPause,
              ),
              Text(
                _position.toString().split('.').first,
                style: TextStyle(
                  color: widget.isMe ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}
