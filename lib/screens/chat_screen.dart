import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';

final _firestore = FirebaseFirestore.instance;
User? loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';

  const ChatScreen({super.key, required this.friendEmail});

  final String friendEmail;

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  String? photoURL;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      setState(() {
        this.user = user;
      });
      if (user != null) {
        _getProfilePicture(user.email!);
      }
    });
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          loggedInUser = user;
        });
        _getProfilePicture(user.email!);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _getProfilePicture(String email) async {
    final userDoc = await _firestore.collection('users').doc(email).get();
    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      setState(() {
        photoURL = data['photoURL'] ?? '';
      });
    }
  }

  Future<void> _removeFriend(String friendEmail) async {
    try {
      final currentUserEmail = loggedInUser!.email;

      // Remove friend from current user's friend list
      await _firestore
          .collection('users')
          .doc(currentUserEmail)
          .collection('friends')
          .doc(friendEmail)
          .delete();

      // Remove current user from friend's friend list
      await _firestore
          .collection('users')
          .doc(friendEmail)
          .collection('friends')
          .doc(currentUserEmail)
          .delete();

      // Optionally, delete the chat document between the two users
      final chatQuery = await _firestore
          .collection('chats')
          .where('users', arrayContains: currentUserEmail)
          .get();
      for (var chatDoc in chatQuery.docs) {
        final chatData = chatDoc.data() as Map<String, dynamic>;
        if ((chatData['users'] as List<dynamic>).contains(friendEmail)) {
          await _firestore.collection('chats').doc(chatDoc.id).delete();
        }
      }

      print('Friend removed successfully!');
    } catch (e) {
      print('Failed to remove friend: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Chat'),
            if (photoURL != null)
              CircleAvatar(
                backgroundImage: NetworkImage(photoURL!),
                radius: 20,
              ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.person_add, color: Colors.pink),
            label:
                const Text('Add Friend', style: TextStyle(color: Colors.pink)),
            onPressed: () {
              showSearch(
                context: context,
                delegate: FriendSearchDelegate(context),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search...',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  // Implement search functionality
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('chats').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final chats = snapshot.data!.docs;
                  List<Future<ChatItem>> chatItemsFutures = [];
                  for (var chat in chats) {
                    final chatData = chat.data() as Map<String, dynamic>;
                    final users = chatData['users'] as List<dynamic>;

                    // Ensure the chat includes the logged-in user
                    if (users.contains(loggedInUser!.email)) {
                      final chatItemFuture = _createChatItem(users, chatData);
                      chatItemsFutures.add(chatItemFuture);
                    }
                  }

                  return FutureBuilder<List<ChatItem>>(
                    future: Future.wait(chatItemsFutures),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final chatItems = snapshot.data!;
                      return ListView.builder(
                        itemCount: chatItems.length,
                        itemBuilder: (context, index) {
                          final chatItem = chatItems[index];
                          return GestureDetector(
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Remove Friend'),
                                    content: const Text(
                                        'Are you sure you want to remove this friend?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await _removeFriend(
                                              chatItem.friendEmail);
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: chatItem.avatarUrl.isNotEmpty
                                    ? NetworkImage(chatItem.avatarUrl)
                                    : null,
                                radius: 25.0,
                              ),
                              title: Text(chatItem.name),
                              subtitle: Text(chatItem.lastMessage),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(
                                      friendEmail: chatItem.friendEmail,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<ChatItem> _createChatItem(
      List<dynamic> users, Map<String, dynamic> chatData) async {
    final partnerEmail = _getChatPartnerEmail(users);
    if (partnerEmail.isEmpty) {
      return ChatItem(
        name: '',
        lastMessage: '',
        timestamp: chatData['timestamp'] ?? Timestamp.now(),
        avatarUrl: '',
        friendEmail: '',
      );
    }
    final userDoc =
        await _firestore.collection('users').doc(partnerEmail).get();

    String name = partnerEmail;
    String photoURL = '';

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      name = data['username'] ?? partnerEmail;
      photoURL = data['photoURL'] ?? '';
    }

    return ChatItem(
      name: name,
      lastMessage: chatData['lastMessage'] ?? '',
      timestamp: chatData['timestamp'] ?? Timestamp.now(),
      avatarUrl: photoURL,
      friendEmail: partnerEmail,
    );
  }

  String _getChatPartnerEmail(List<dynamic> users) {
    return users.firstWhere(
      (email) => email != loggedInUser!.email,
      orElse: () => '',
    );
  }
}

class ChatItem {
  final String name;
  final String lastMessage;
  final Timestamp timestamp;
  final String avatarUrl;
  final String friendEmail;

  ChatItem({
    required this.name,
    required this.lastMessage,
    required this.timestamp,
    required this.avatarUrl,
    required this.friendEmail,
  });
}

class FriendSearchDelegate extends SearchDelegate {
  final BuildContext context;
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference chatsCollection =
      FirebaseFirestore.instance.collection('chats');

  FriendSearchDelegate(this.context);

  Future<void> _addFriend(String friendEmail) async {
    try {
      final currentUserEmail = loggedInUser!.email;

      // Ensure the user is not trying to add themselves as a friend
      if (friendEmail == currentUserEmail) {
        _showDialog(context, 'Cannot add yourself as a friend');
        return;
      }

      // Check for duplicate
      final friendDoc = await usersCollection
          .doc(currentUserEmail)
          .collection('friends')
          .doc(friendEmail)
          .get();
      if (friendDoc.exists) {
        _showDialog(context, 'Friend already added');
        return;
      }

      // Add friend to current user's friend list
      await usersCollection
          .doc(currentUserEmail)
          .collection('friends')
          .doc(friendEmail)
          .set({
        'email': friendEmail,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Add current user to friend's friend list
      await usersCollection
          .doc(friendEmail)
          .collection('friends')
          .doc(currentUserEmail)
          .set({
        'email': currentUserEmail,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Create a chat between the two users
      await chatsCollection.add({
        'users': [currentUserEmail, friendEmail],
        'lastMessage': '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _showDialog(context, 'Friend added successfully!');
    } catch (e) {
      _showDialog(context, 'Failed to add friend: $e');
    }
  }

  void _showDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Friend Addition'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: usersCollection.where('email', isEqualTo: query).get(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
              child: Text('An error occurred, please try again.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found'));
        }
        var users = snapshot.data!.docs;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var user = users[index];
            final data = user.data() as Map<String, dynamic>;
            final username = data['username'] ?? user['email'];
            return ListTile(
              title: Text(username),
              subtitle: Text(user['email']),
              trailing: IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: () {
                  _addFriend(user['email']);
                  close(context, null);
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
