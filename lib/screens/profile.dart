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
import 'package:logger/logger.dart';

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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nomorindukController = TextEditingController();
  final CollectionReference _users = FirebaseFirestore.instance.collection('users');
  final logger = Logger();

  String imageUrl = '';
  String _imagePath = '';
  XFile? _pickedImage;
  bool _isImageChanged = false;
  bool _isLoading = false;

  @override
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
          String nomorInduk = userDoc.data()?['nomor_induk'] ?? '';
          String telepon = userDoc.data()?['telepon'] ?? '';
          _jabatanController.text = jabatan;
          _emailController.text = email;
          _teleponController.text = telepon;
          _nameController.text = name;
          _nomorindukController.text = nomorInduk;
          if (mounted) {
            Provider.of<UserData>(context, listen: false).updateUserData(
                name, email, jabatan, image, nomorInduk, telepon);
          }
        }
      }
    } catch (error) {
      logger.e("Error fetching user data: $error");
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
            backgroundContainer(context),
            SingleChildScrollView(
              child: Positioned(
                top: 90,
                child: mainContainer(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Column backgroundContainer(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 240,
          decoration: const BoxDecoration(
            color: Color(0xFF1A73E8),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Bottom()))
                            .then((data) {});
                      },
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Text(
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

  Container mainContainer() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      height: 710,
      width: 340,
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            foto(),
            const SizedBox(
              height: 20,
              width: 200,
              child: Divider(
                color: Colors.white,
              ),
            ),
            nama(),
            nomorinduk(),
            email(),
            jabatan(),
            telepon(),
            update(),
            const SizedBox(height: 50),
          ],
        ),
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
        boxShadow: const [
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
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(50),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: () => _pickImage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Center nama() {
  //   final userData = Provider.of<UserData>(context);
  //   final String accountName = userData.name ?? 'Name';
  //   return Center(
  //     child: Text(
  //       "$accountName",
  //       textAlign:
  //           TextAlign.center, // Teks akan diatur ke tengah secara horizontal
  //       style: TextStyle(
  //         fontSize: 33.0,
  //         color: Color(0xFF1A73E8),
  //         fontWeight: FontWeight.bold,
  //         fontFamily: "Pacifico",
  //       ),
  //     ),
  //   );
  // }

  Padding nama() {
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25, bottom: 15),
      child: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Nama',
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
        style: const TextStyle(
          color: Colors.blueAccent,
          fontSize: 20,
          fontFamily: "Source Sans Pro",
        ),
        enabled: false,
      ),
    );
  }

  // Text nomorinduk() {
  //   final userData = Provider.of<UserData>(context);
  //   final String accountNomorInduk = userData.nomor_induk ?? 'Nomor Induk';
  //   return Text(
  //     "$accountNomorInduk",
  //     style: TextStyle(
  //         fontSize: 25,
  //         color: Color(0xFF1A73E8),
  //         letterSpacing: 2.5,
  //         fontWeight: FontWeight.bold,
  //         fontFamily: "Source Sans Pro"),
  //   );
  // }

  Padding nomorinduk() {
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25, bottom: 15),
      child: TextField(
        controller: _nomorindukController,
        decoration: const InputDecoration(
          labelText: 'Nomor Induk',
          labelStyle: TextStyle(
            color: Colors.blueAccent,
            fontFamily: "Source Sans Pro",
          ),
          prefixIcon: Icon(
            Icons.format_list_numbered_sharp,
            color: Colors.blueAccent,
          ),
          border: OutlineInputBorder(),
        ),
        style: const TextStyle(
          color: Colors.blueAccent,
          fontSize: 20,
          fontFamily: "Source Sans Pro",
        ),
        enabled: false,
      ),
    );
  }

  Padding email() {
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25, bottom: 15),
      child: TextField(
        controller: _emailController,
        decoration: const InputDecoration(
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
        style: const TextStyle(
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
        decoration: const InputDecoration(
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
        style: const TextStyle(
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
        decoration: const InputDecoration(
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
        style: const TextStyle(
          color: Colors.blueAccent,
          fontSize: 20,
          fontFamily: "Source Sans Pro",
        ),
      ),
    );
  }

  Padding update() {
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25, top: 25),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              color: Color.fromARGB(255, 219, 241, 251),
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
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

                  String fileName = 'images/$uniqueFileName-$formattedDateTime.jpg';

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

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Profil anda berhasil diubah'),
                        backgroundColor: Colors.blueAccent,
                      ));
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) => const Bottom()));
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Document snapshot is null'),
                        backgroundColor: Colors.red,
                      ));
                    }
                  }
                } catch (error) {
                  logger.e("Error updating profile: $error");
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
          child: _isLoading
            ? const CircularProgressIndicator()
            : const Text(
                'Update Data Profile',
                style: TextStyle(color: Colors.white),
              ),
      ),
    );
  }
}
