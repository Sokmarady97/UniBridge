import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  static const String id = 'profile_screen';

  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  String? _profileImageUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.email).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _profileImageUrl =
              data.containsKey('photoURL') ? data['photoURL'] : null;
          nameController.text = data.containsKey('name') ? data['name'] : '';
          bioController.text = data.containsKey('bio') ? data['bio'] : '';
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> _uploadImage() async {
    if (_image == null) {
      _showErrorDialog('No image selected');
      return;
    }

    if (nameController.text.isEmpty || bioController.text.isEmpty) {
      _showErrorDialog('Name and bio cannot be empty');
      return;
    }

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${user.uid}.jpg');
        await ref.putFile(_image!);
        final url = await ref.getDownloadURL();
        await _firestore.collection('users').doc(user.email).update({
          'photoURL': url,
          'name': nameController.text,
          'bio': bioController.text
        });
        await user.updatePhotoURL(url);
        setState(() {
          _profileImageUrl = url;
        });
        Navigator.pop(context); // Close the profile screen
      } else {
        _showErrorDialog('User is not logged in');
      }
    } catch (e) {
      print(e); // For debugging
      _showErrorDialog('Failed to upload image: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void saveProfile() async {
    if (_image == null) {
      _showErrorDialog('No image selected');
      return;
    }

    String name = nameController.text;
    String bio = bioController.text;

    if (name.isEmpty || bio.isEmpty) {
      _showErrorDialog('Name and bio cannot be empty');
      return;
    }

    try {
      // First upload the image and get the URL
      User? user = _auth.currentUser;
      if (user != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${user.uid}.jpg');
        await ref.putFile(_image!);
        final url = await ref.getDownloadURL();

        // Update Firestore with new data
        await _firestore
            .collection('users')
            .doc(user.email)
            .update({'photoURL': url, 'name': name, 'bio': bio});
        await user.updatePhotoURL(url);

        setState(() {
          _profileImageUrl = url;
        });

        Navigator.pop(context); // Close the profile screen if success
      } else {
        _showErrorDialog('User is not logged in');
      }
    } catch (e) {
      print(e); // For debugging
      _showErrorDialog('Failed to save profile: $e');
    }
  }

  // Method to open the link
  Future<void> _launchURL() async {
    const url = 'https://forms.gle/PnQ1d4RAggHWFE2K6';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Stack(
                children: [
                  _image != null
                      ? CircleAvatar(
                          radius: 64,
                          backgroundImage: FileImage(_image!),
                        )
                      : CircleAvatar(
                          radius: 64,
                          backgroundImage: _profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : const NetworkImage(
                                  'https://png.pngitem.com/pimgs/s/421-4212266_transparent-default-avatar-png-default-avatar-images-png.png'),
                        ),
                  Positioned(
                    bottom: -10,
                    left: 80,
                    child: IconButton(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_a_photo),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter Name',
                  contentPadding: EdgeInsets.all(10),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: bioController,
                decoration: const InputDecoration(
                  hintText: 'Enter Bio',
                  contentPadding: EdgeInsets.all(10),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: saveProfile,
                child: const Text('Save Profile'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _launchURL, // Button to launch the URL
                child: const Text('Request for improvement'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
