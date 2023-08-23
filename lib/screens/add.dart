import 'dart:io';
import 'dart:typed_data';

import 'package:absensi_flutter/models/user_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class Add_Screen extends StatefulWidget {
  const Add_Screen({super.key});

  @override
  State<Add_Screen> createState() => _Add_ScreenState();
}

class _Add_ScreenState extends State<Add_Screen> {
  final CollectionReference _karyawan =
      FirebaseFirestore.instance.collection('karyawans');
  final TextEditingController _nameController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  String imageUrl = '';
  String _imagePath = '';
  bool _isSaving = false;

  String? _selectedValue;
  List<String> listOfValue = ['Masuk', 'Izin', 'Sakit'];

  void initState() {
    super.initState();
    fetchUserDataFromFirestore();
  }

  Future<void> fetchUserDataFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var userDoc =  await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          String name = userDoc.data()?['name'] ?? '';
          String email = userDoc.data()?['email'] ?? '';
          String jabatan = userDoc.data()?['jabatan'] ?? '';
          String image = userDoc.data()?['image'] ?? '';
          String nomor_induk = userDoc.data()?['nomor_induk'] ?? '';
          String telepon = userDoc.data()?['telepon'] ?? '';
          _nameController.text = name;
          Provider.of<UserData>(context, listen: false).updateUserData(name, email, jabatan, image, nomor_induk, telepon);
        }
      }
    } catch (error) {
      print("Error fetching user data: $error");
    }
  }

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

  Container main_container() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      height: 650,
      width: 340,
      child: Column(
        children: [
          SizedBox(height: 40),
          nama(),
          SizedBox(height: 30),
          keterangan(),
          SizedBox(height: 30),
          foto(),
          SizedBox(height: 20),
          if (_imagePath.isNotEmpty)
            Center(
              child: Container(
                height: 250,
                width: 170,
                child: _imagePath != ''
                    ? Image.file(
                        File(_imagePath),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
          // Spacer(),
          SizedBox(height: 30),
          save(),
          SizedBox(height: 25),
        ],
      ),
    );
  }

  GestureDetector save() {
    return GestureDetector(
      onTap: _isSaving
          ? null
          : () async {
              setState(() {
                _isSaving = true;
              });

              final String name = _nameController.text;
              final String keterangan = _selectedValue.toString();

              // Get current latitude and longitude
              _currentLocation = await _getCurrentLocation();
              final String latitude = _currentLocation!.latitude.toString();
              final String longitude = _currentLocation!.longitude.toString();

              if (_imagePath.isEmpty) {
                setState(() {
                  _isSaving =
                      false;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Upload Foto Absen Anda'),
                  backgroundColor: Colors.blueAccent,
                ));
                return;
              }

              if (keterangan == "Masuk" ||
                  keterangan == "Izin" ||
                  keterangan == "Sakit") {
                Uint8List imageBytes = await File(_imagePath).readAsBytes();
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

                String imageUrl = await referenceImageToUpload.getDownloadURL();

                // Generate custom id : decrement
                int docCustom = 3000000000000-DateTime.now().millisecondsSinceEpoch;
                String docId = docCustom.toString();
                // Create a reference to the document using the custom ID
                DocumentReference documentReference = _karyawan.doc(docId);

                await documentReference.set({
                  "name": name,
                  "timestamps": FieldValue.serverTimestamp(),
                  "image": imageUrl,
                  "latitude": latitude,
                  "longitude": longitude,
                  "keterangan": keterangan,
                });

                setState(() {
                  _isSaving =
                      false;
                });

                _nameController.text = '';
                _imagePath = '';

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Data Absensi anda berhasil tersimpan'),
                  backgroundColor: Colors.blueAccent,
                ));
                Navigator.pop(context);
              } else {
                setState(() {
                  _isSaving =
                      false;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Masukkan keterangan kehadiran'),
                  backgroundColor: Colors.blueAccent,
                ));
              }
            },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Color(0xFF1A73E8),
        ),
        width: 120,
        height: 50,
        child: _isSaving
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              )
            : Text(
                'Simpan Data',
                style: TextStyle(
                  fontFamily: 'f',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 17,
                ),
              ),
      ),
    );
  }

  Padding nama() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: 'Nama',
          labelStyle: TextStyle(
            color: Colors.blueAccent,
            fontFamily: "Source Sans Pro",
          ),
          border: OutlineInputBorder(),
        ),
        style: TextStyle(
          color: Colors.blueAccent,
          fontSize: 18,
          fontFamily: "Source Sans Pro",
        ),
        enabled: false,
      ),
    );
  }

  Padding keterangan() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          width: 0.5,
          color: Color(0xffC5C5C5),
        ),
      ),
      child: DropdownButton<String>(
        value: _selectedValue,
        onChanged: ((value) {
          setState(() {
            _selectedValue = value as String?;
          });
        }),
        items: listOfValue
            .map((e) => DropdownMenuItem(
                  child: Container(
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        Text(
                          e,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.blueAccent,
                            fontFamily: "Source Sans Pro",
                          ),
                        ),
                      ],
                    ),
                  ),
                  value: e,
                ))
            .toList(),
        selectedItemBuilder: (BuildContext context) => listOfValue
            .map((e) => Row(
                  children: [
                    Text(
                      e,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.blueAccent,
                        fontFamily: "Source Sans Pro",
                      ),
                    ),
                  ],
                ))
            .toList(),
        hint: Padding(
          padding: const EdgeInsets.only(left: 1),
          child: Text(
            'Pilih Keterangan',
            style: TextStyle(
              fontSize: 18,
              color: Colors.blueAccent,
              fontFamily: "Source Sans Pro",
            ),
          ),
        ),
        dropdownColor: Colors.white,
        isExpanded: true,
        underline: Container(),
      ),
    ),
  );
}


  Padding foto() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Colors.blueAccent,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Colors.blueAccent,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onPressed: () => _pickAndSetImage(),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Ambil Foto',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                      'Form Absensi',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    Icon(
                      Icons.attach_file_outlined,
                      color: Colors.white,
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  // FUNGSI - FUNGSI
  // Fungsi Pick Image tanpa menyimpan ke Firebase
  Future<void> _pickAndSetImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? file = await imagePicker.pickImage(source: ImageSource.camera);
    if (file == null) return;
    setState(() {
      _imagePath = file.path;
    });
  }

  // Fungsi Pembantu Image untuk mengatur imageUrl dengan menggunakan setState.
  void _setImageUrl(String imageUrl) {
    setState(() {
      this.imageUrl = imageUrl;
    });
  }

  // Komponen Pengambilan Lokasi Saat Ini
  Position? _currentLocation;
  late bool servicePermission = false;
  late LocationPermission permission;
  Future<Position> _getCurrentLocation() async {
    // check if we have permission to access location service
    servicePermission = await Geolocator.isLocationServiceEnabled();
    if (!servicePermission) {
      print("Service Disabled");
    }
    // service enabled
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return await Geolocator.getCurrentPosition();
  }
}
