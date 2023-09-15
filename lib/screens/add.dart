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
import 'package:image/image.dart' as img;

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
  bool isExist = false;

  String? _selectedValueMasuk;
  List<String> listOfMasuk = ['Masuk', 'Izin'];
  String? _selectedValuePulang;
  List<String> listOfPulang = ['Tidak Lembur', 'Izin'];

  void initState() {
    super.initState();
    fetchUserDataFromFirestore();
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
          _nameController.text = name;
          Provider.of<UserData>(context, listen: false).updateUserData(
              name, email, jabatan, image, nomor_induk, telepon);
        }
      }
    } catch (error) {
      print("Error fetching user data: $error");
    }
  }

  Widget build(BuildContext context) {
    final currentTime = DateTime.now();
    String timePeriod;

    if (currentTime.hour >= 6 && currentTime.hour <= 11) {
      timePeriod = "datang";
    } else if (currentTime.hour >= 12 && currentTime.hour <= 17) {
      timePeriod = "pulang";
    } else if (currentTime.hour >= 18 && currentTime.hour <= 23) {
      timePeriod = "lembur";
    } else {
      timePeriod = "tidak ada";
    }

    Widget containerToDisplay;
    if (timePeriod == "tidak ada") {
      containerToDisplay = main_container_noabsen();
    } else {
      containerToDisplay = main_container();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            background_container(context),
            Positioned(
              top: 90,
              child: containerToDisplay,
            ),
          ],
        ),
      ),
    );
  }

  Container main_container_noabsen() {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      height: 650,
      width: 340,
      child: Column(
        children: [
          SizedBox(height: 100),
          informasi(),
        ],
      ),
    );
  }

  Container informasi() {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Color(0xFF1A73E8),
      ),
      width: 250,
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 80,
            ),
            SizedBox(height: 20),
            Text(
              'Tidak ada absen untuk ditampilkan pada jam ini',
              style: TextStyle(
                fontFamily: 'f',
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 40,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Container main_container() {
    final currentTime = DateTime.now();
    String timePeriod;

    if (currentTime.hour >= 6 && currentTime.hour <= 11) {
      timePeriod = "datang";
    } else if (currentTime.hour >= 12 && currentTime.hour <= 17) {
      timePeriod = "pulang";
    } else if (currentTime.hour >= 18 && currentTime.hour <= 23) {
      timePeriod = "lembur";
    } else {
      timePeriod = "tidak ada";
    }

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
          if (timePeriod == "datang") keterangan_datang(),
          if (timePeriod == "pulang") keterangan_pulang(),
          if (timePeriod == "lembur") keterangan_lembur(),
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
          SizedBox(height: 30),
          if (timePeriod == "datang") save_datang(),
          if (timePeriod == "pulang") save_pulang(),
          if (timePeriod == "lembur") save_lembur(),
          SizedBox(height: 25),
        ],
      ),
    );
  }

  GestureDetector save_datang() {
    return GestureDetector(
      onTap: _isSaving
          ? null
          : () async {
              setState(() {
                _isSaving = true;
              });

              final String name = _nameController.text;
              final String keterangan = _selectedValueMasuk.toString();
              String latitude = '';
              String longitude = '';
              String status = '';
              DateTime currentTime = DateTime.now();
              DateTime targetTime = DateTime(
                  currentTime.year, currentTime.month, currentTime.day, 8, 4);

              if (currentTime.isAfter(targetTime)) {
                status = 'Terlambat';
              } else {
                status = 'Tepat Waktu';
              }

              _currentLocation = await _getCurrentLocation();
              if (_currentLocation!.accuracy < 10) {
                setState(() {
                  _isSaving = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text('Terdeteksi penggunaan Fake GPS pada device anda'),
                  backgroundColor: Colors.blueAccent,
                ));
                return;
              } else {
                latitude = _currentLocation!.latitude.toString();
                longitude = _currentLocation!.longitude.toString();
              }

              if (_imagePath.isEmpty) {
                setState(() {
                  _isSaving = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Upload Foto Absen Anda'),
                  backgroundColor: Colors.blueAccent,
                ));
                return;
              }

              if (keterangan == "Masuk" || keterangan == "Izin") {
                bool dataExists = await checkIfDataExistsPulang(name, "Datang");
                if (dataExists) {
                  setState(() {
                    _isSaving = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Anda tidak dapat menambahkan data absensi karena sudah tersimpan sebelumnya'),
                    backgroundColor: Colors.blueAccent,
                  ));
                  return;
                }
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

                int docCustom =
                    3000000000000 - DateTime.now().millisecondsSinceEpoch;
                String docId = docCustom.toString();
                DocumentReference documentReference = _karyawan.doc(docId);

                await documentReference.set({
                  "name": name,
                  "timestamps": FieldValue.serverTimestamp(),
                  "image": imageUrl,
                  "latitude": latitude,
                  "longitude": longitude,
                  "keterangan": keterangan,
                  "status": status,
                  "kategori": "Datang"
                });

                setState(() {
                  _isSaving = false;
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
                  _isSaving = false;
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

  GestureDetector save_pulang() {
    return GestureDetector(
      onTap: _isSaving
          ? null
          : () async {
              setState(() {
                _isSaving = true;
              });

              final String name = _nameController.text;
              final String keterangan = _selectedValuePulang.toString();
              String latitude = '';
              String longitude = '';

              _currentLocation = await _getCurrentLocation();
              if (_currentLocation!.accuracy < 10) {
                setState(() {
                  _isSaving = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text('Terdeteksi penggunaan Fake GPS pada device anda'),
                  backgroundColor: Colors.blueAccent,
                ));
                return;
              } else {
                latitude = _currentLocation!.latitude.toString();
                longitude = _currentLocation!.longitude.toString();
              }

              if (_imagePath.isEmpty) {
                setState(() {
                  _isSaving = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Upload Foto Absen Anda'),
                  backgroundColor: Colors.blueAccent,
                ));
                return;
              }

              if (keterangan == "Tidak Lembur" || keterangan == "Izin") {
                bool dataExists = await checkIfDataExistsPulang(name, "Pulang");
                if (dataExists) {
                  setState(() {
                    _isSaving = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Anda tidak dapat menambahkan data absensi karena sudah tersimpan sebelumnya'),
                    backgroundColor: Colors.blueAccent,
                  ));
                  return;
                }

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

                int docCustom =
                    3000000000000 - DateTime.now().millisecondsSinceEpoch;
                String docId = docCustom.toString();
                DocumentReference documentReference = _karyawan.doc(docId);

                await documentReference.set({
                  "name": name,
                  "timestamps": FieldValue.serverTimestamp(),
                  "image": imageUrl,
                  "latitude": latitude,
                  "longitude": longitude,
                  "keterangan": keterangan,
                  "status": "Tepat Waktu",
                  "kategori": "Pulang"
                });

                setState(() {
                  _isSaving = false;
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
                  _isSaving = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Masukkan keterangan kepulangan'),
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

  GestureDetector save_lembur() {
    return GestureDetector(
      onTap: _isSaving
          ? null
          : () async {
              setState(() {
                _isSaving = true;
              });

              final String name = _nameController.text;
              String latitude = '';
              String longitude = '';

              _currentLocation = await _getCurrentLocation();
              if (_currentLocation!.accuracy < 10) {
                setState(() {
                  _isSaving = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text('Terdeteksi penggunaan Fake GPS pada device anda'),
                  backgroundColor: Colors.blueAccent,
                ));
                return;
              } else {
                latitude = _currentLocation!.latitude.toString();
                longitude = _currentLocation!.longitude.toString();
              }

              if (_imagePath.isEmpty) {
                setState(() {
                  _isSaving = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Upload Foto Absen Anda'),
                  backgroundColor: Colors.blueAccent,
                ));
                return;
              }

              bool dataExists = await checkIfDataExistsPulang(name, "Pulang");
              if (dataExists) {
                setState(() {
                  _isSaving = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'Anda tidak dapat menambahkan data absensi karena sudah tersimpan sebelumnya'),
                  backgroundColor: Colors.blueAccent,
                ));
                return;
              }

              Uint8List imageBytes = await File(_imagePath).readAsBytes();
              String uniqueFileName =
                  DateTime.now().millisecondsSinceEpoch.toString();
              String formattedDateTime =
                  DateFormat('yyyy-MM-dd').format(DateTime.now());

              String fileName =
                  'images/' + uniqueFileName + '_' + formattedDateTime + '.jpg';
              Reference referenceImageToUpload =
                  FirebaseStorage.instance.ref().child(fileName);
              await referenceImageToUpload.putData(imageBytes);

              String imageUrl = await referenceImageToUpload.getDownloadURL();

              int docCustom =
                  3000000000000 - DateTime.now().millisecondsSinceEpoch;
              String docId = docCustom.toString();
              DocumentReference documentReference = _karyawan.doc(docId);

              await documentReference.set({
                "name": name,
                "timestamps": FieldValue.serverTimestamp(),
                "image": imageUrl,
                "latitude": latitude,
                "longitude": longitude,
                "keterangan": "Lembur",
                "status": "Tepat Waktu",
                "kategori": "Pulang"
              });

              setState(() {
                _isSaving = false;
              });

              _nameController.text = '';
              _imagePath = '';

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Data Absensi anda berhasil tersimpan'),
                backgroundColor: Colors.blueAccent,
              ));
              Navigator.pop(context);
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

  Padding keterangan_lembur() {
    TextEditingController _keteranganController = TextEditingController(
      text: "Lembur",
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _keteranganController,
        decoration: InputDecoration(
          labelText: 'Keterangan',
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

  Padding keterangan_datang() {
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
          value: _selectedValueMasuk,
          onChanged: ((value) {
            setState(() {
              _selectedValueMasuk = value as String?;
            });
          }),
          items: listOfMasuk
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
          selectedItemBuilder: (BuildContext context) => listOfMasuk
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

  Padding keterangan_pulang() {
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
          value: _selectedValuePulang,
          onChanged: ((value) {
            setState(() {
              _selectedValuePulang = value as String?;
            });
          }),
          items: listOfPulang
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
          selectedItemBuilder: (BuildContext context) => listOfPulang
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
    final currentTime = DateTime.now();
    String timePeriod;

    if (currentTime.hour >= 6 && currentTime.hour <= 11) {
      timePeriod = "datang";
    } else if (currentTime.hour >= 12 && currentTime.hour <= 17) {
      timePeriod = "pulang";
    } else if (currentTime.hour >= 18 && currentTime.hour <= 23) {
      timePeriod = "lembur";
    } else {
      timePeriod = "tidak ada";
    }

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
                    if (timePeriod == "datang")
                      Text(
                        'Form Absensi Datang',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    if (timePeriod == "pulang")
                      Text(
                        'Form Absensi Pulang',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    if (timePeriod == "lembur")
                      Text(
                        'Form Absensi Lembur',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    if (timePeriod == "tidak ada")
                      Text(
                        'Absen tidak ditemukan',
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
  Future<bool> checkIfDataExistsDatang(String name, String kategori) async {
    final DateTime now = DateTime.now();

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('karyawans')
        .where('name', isEqualTo: name)
        .where('kategori', isEqualTo: kategori)
        .get();

    isExist = checkAbsenToday(querySnapshot.docs, now.year, now.month, now.day);

    return isExist;
  }

  Future<bool> checkIfDataExistsPulang(String name, String kategori) async {
    final DateTime now = DateTime.now();

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('karyawans')
        .where('name', isEqualTo: name)
        .where('kategori', isEqualTo: kategori)
        .get();

    isExist = checkAbsenToday(querySnapshot.docs, now.year, now.month, now.day);

    return isExist;
  }

  bool checkAbsenToday(
      List<QueryDocumentSnapshot> documents, int year, int month, int day) {
    bool absenExist = false;
    for (var doc in documents) {
      DateTime docTimestamp = (doc['timestamps'] as Timestamp).toDate();
      if (docTimestamp.year == year &&
          docTimestamp.month == month &&
          docTimestamp.day == day) {
        absenExist = true;
      }
    }

    return absenExist;
  }

  Future<void> _pickAndSetImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? file = await imagePicker.pickImage(source: ImageSource.camera);
    if (file == null) return;

    final File compressedImage = await compressImage(File(file.path), 200);

    setState(() {
      _imagePath = file.path;
    });
  }

  Future<File> compressImage(File file, int maxSizeInKB) async {
    final img.Image? image = img.decodeImage(file.readAsBytesSync());
    if (image == null) {
      return file;
    }

    final int targetSize = maxSizeInKB * 1024;
    int currentSize = file.lengthSync();
    int quality = 90;

    while (currentSize > targetSize) {
      final img.Image compressedImage = img.copyResize(image,
          width: image.width ~/ 2, height: image.height ~/ 2);
      quality -= 10;
      final compressedImageData =
          img.encodeJpg(compressedImage, quality: quality);
      final compressedFile = File(file.path)
        ..writeAsBytesSync(compressedImageData);
      currentSize = compressedFile.lengthSync();
    }

    return file;
  }

  Position? _currentLocation;
  late bool servicePermission = false;
  late LocationPermission permission;
  Future<Position> _getCurrentLocation() async {
    servicePermission = await Geolocator.isLocationServiceEnabled();
    if (!servicePermission) {
      print("Service Disabled");
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return await Geolocator.getCurrentPosition();
  }
}
