import 'dart:io';
import 'dart:typed_data';

import 'package:absensi_flutter/models/user_data.dart';
import 'package:absensi_flutter/widgets/bottomnavigationbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  final DocumentSnapshot? documentSnapshot;

  const ProfilePage({Key? key, this.documentSnapshot}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _jabatanController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();
  final CollectionReference _users =
      FirebaseFirestore.instance.collection('users');

  String imageUrl = '';
  String _imagePath = '';
  XFile? _pickedImage;
  bool _isImageChanged = false;
  bool _isLoading = false;

  void initState() {
    super.initState();
    fetchUserDataFromFirestore();
  }

  // Fungsi Pick Image tanpa menyimpan ke Firebase
  void _pickImage() async {
    ImagePicker imagePicker = ImagePicker();
    _pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);
    if (_pickedImage != null) {
      setState(() {
        _imagePath = _pickedImage!.path;
        _isImageChanged = true;
      });
    }
  }

  // Fungsi Pembantu Image untuk mengatur imageUrl dengan menggunakan setState.
  void _setImageUrl(String imageUrl) {
    setState(() {
      this.imageUrl = imageUrl;
    });
  }

  Future<void> fetchUserDataFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          String name = userDoc.data()?['name'] ?? '';
          String email = userDoc.data()?['email'] ?? '';
          String jabatan = userDoc.data()?['jabatan'] ?? '';
          String image = userDoc.data()?['image'] ?? '';
          String nomor_induk = userDoc.data()?['nomor_induk'] ?? '';
          String telepon = userDoc.data()?['telepon'] ?? '';
          _jabatanController.text = jabatan;
          _emailController.text = email;
          _teleponController.text = telepon;
          Provider.of<UserData>(context, listen: false).updateUserData(
              name, email, jabatan, image, nomor_induk, telepon);
        }
      }
    } catch (error) {
      print("Error fetching user data: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            background_container(context),
            Positioned(
              top: 120,
              child: main_container(),
            ),
          ],
        ),
      ),
    );
  }

  Column background_container(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            color: Color(0xFF1A73E8),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 40),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Text(
                      'Profil Saya',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Container main_container() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      height: 700,
      width: 340,
      child: Column(
        children: <Widget>[
          foto(),
          nama(),
          nomorinduk(),
          SizedBox(
            height: 20,
            width: 200,
            child: Divider(
              color: Colors.white,
            ),
          ),
          email(),
          jabatan(),
          telepon(),
          update(),
        ],
      ),
    );
  }

  Container foto() {
    final userData = Provider.of<UserData>(context);
    final String accountImage = userData.image ??
        'https://img.freepik.com/free-icon/user_318-159711.jpg';
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff7c94b6),
        image: DecorationImage(
          image: NetworkImage(accountImage),
          fit: BoxFit.fitWidth,
        ),
        border: Border.all(
          color: Colors.blueAccent,
          width: 4,
        ),
        borderRadius: BorderRadius.circular(125),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 3,
          ),
        ],
      ),
      height: 225,
      width: 225,
      margin: const EdgeInsets.only(left: 50.0, right: 30.0, top: 15),
      child: Stack(
        children: [
          if (_imagePath.isNotEmpty)
            ClipOval(
              child: Image.file(
                File(_imagePath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              margin: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(50),
              ),
              child: IconButton(
                icon: Icon(Icons.camera_alt, color: Colors.white),
                onPressed: () => _pickImage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Text nama() {
    final userData = Provider.of<UserData>(context);
    final String accountName = userData.name ?? 'Name';
    return Text(
      "$accountName",
      style: TextStyle(
        fontSize: 40.0,
        color: Color(0xFF1A73E8),
        fontWeight: FontWeight.bold,
        fontFamily: "Pacifico",
      ),
    );
  }

  Text nomorinduk() {
    final userData = Provider.of<UserData>(context);
    final String accountNomorInduk = userData.nomor_induk ?? 'Nomor Induk';
    return Text(
      "$accountNomorInduk",
      style: TextStyle(
          fontSize: 30,
          color: Color.fromARGB(255, 29, 101, 245),
          letterSpacing: 2.5,
          fontWeight: FontWeight.bold,
          fontFamily: "Source Sans Pro"),
    );
  }

  Padding email() {
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25, bottom: 15),
      child: TextField(
        controller: _emailController,
        decoration: InputDecoration(
          labelText: 'Email',
          labelStyle: TextStyle(
            color: Colors.blueAccent,
            fontFamily: "Source Sans Pro",
          ),
          prefixIcon: Icon(
            Icons.email,
            color: Colors.blueAccent,
          ),
          border: OutlineInputBorder(),
        ),
        style: TextStyle(
          color: Colors.blueAccent,
          fontSize: 20,
          fontFamily: "Source Sans Pro",
        ),
        enabled: false,
      ),
    );
  }

  Padding jabatan() {
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25, bottom: 15),
      child: TextField(
        controller: _jabatanController,
        decoration: InputDecoration(
          labelText: 'Jabatan',
          labelStyle: TextStyle(
            color: Colors.blueAccent,
            fontFamily: "Source Sans Pro",
          ),
          prefixIcon: Icon(
            Icons.person,
            color: Colors.blueAccent,
          ),
          border: OutlineInputBorder(),
        ),
        style: TextStyle(
          color: Colors.blueAccent,
          fontSize: 20,
          fontFamily: "Source Sans Pro",
        ),
      ),
    );
  }

  Padding telepon() {
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25, bottom: 15),
      child: TextField(
        controller: _teleponController,
        decoration: InputDecoration(
          labelText: 'Telepon',
          labelStyle: TextStyle(
            color: Colors.blueAccent,
            fontFamily: "Source Sans Pro",
          ),
          prefixIcon: Icon(
            Icons.phone,
            color: Colors.blueAccent,
          ),
          border: OutlineInputBorder(),
        ),
        style: TextStyle(
          color: Colors.blueAccent,
          fontSize: 20,
          fontFamily: "Source Sans Pro",
        ),
      ),
    );
  }

  Padding update() {
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Colors.blueAccent,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Color.fromARGB(255, 219, 241, 251),
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator()
            : Text(
                'Update Data Profile',
                style: TextStyle(color: Colors.white),
              ),
        onPressed: _isLoading
            ? null
            : () async {
                final String telepon = _teleponController.text;
                final String jabatan = _jabatanController.text;
                String newImageUrl = imageUrl;

                if (_isImageChanged) {
                  Uint8List imageBytes = await _pickedImage!.readAsBytes();
                  String uniqueFileName =
                      DateTime.now().millisecondsSinceEpoch.toString();
                  String formattedDateTime =
                      DateFormat('yyyy-MM-dd').format(DateTime.now());

                  String fileName = 'images/' +
                      uniqueFileName +
                      '_' +
                      formattedDateTime +
                      '.jpg';
                  Reference referenceImageToUpload =
                      FirebaseStorage.instance.ref().child(fileName);
                  await referenceImageToUpload.putData(imageBytes);

                  newImageUrl = await referenceImageToUpload.getDownloadURL();
                }

                setState(() {
                  _isLoading = true;
                });

                try {
                  if (widget.documentSnapshot != null) {
                    Map<String, dynamic> updatedData = {
                      "telepon": telepon,
                      "jabatan": jabatan,
                    };

                    if (_isImageChanged) {
                      updatedData["image"] = newImageUrl;
                    }

                    await _users
                        .doc(widget.documentSnapshot!.id)
                        .update(updatedData);

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Profil anda berhasil diubah'),
                      backgroundColor: Colors.blueAccent,
                    ));
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => Bottom()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Document snapshot is null'),
                      backgroundColor: Colors.red,
                    ));
                  }
                  ;
                } catch (error) {
                  print("Error updating profile: $error");
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
      ),
    );
  }
}
