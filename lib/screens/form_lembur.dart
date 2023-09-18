import 'package:absensi_flutter/models/user_data.dart';
import 'package:absensi_flutter/widgets/bottomnavigationbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class FormLembur extends StatefulWidget {
  const FormLembur({super.key});

  @override
  State<FormLembur> createState() => FormLemburState();
}

class FormLemburState extends State<FormLembur> {
  final CollectionReference _karyawan =
      FirebaseFirestore.instance.collection('lemburs');
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _alasanController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool _isSaving = false;
  bool isExist = false;
  final logger = Logger();

  String? _selectedDurasi;
  List<String> listOfDurasi = ['1 jam', '2 jam', '3 jam', '4 jam', '5 jam', '6 jam'];

  @override
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
          String nomorInduk = userDoc.data()?['nomor_induk'] ?? '';
          String telepon = userDoc.data()?['telepon'] ?? '';
          _nameController.text = name;
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
            Positioned(
              top: 90,
              child: mainContainer(),
            ),
          ],
        ),
      ),
    );
  }

  Container mainContainer() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      height: 650,
      width: 340,
      child: Column(
        children: [
          const  SizedBox(height: 40),
          nama(),
          const SizedBox(height: 30),
          durasi(),
          const SizedBox(height: 30),
          alasan(),
          const SizedBox(height: 30),
          save(),
          const SizedBox(height: 25),
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
              final String alasan = _alasanController.text;
              final String durasi = _selectedDurasi.toString();
              bool status = false;

              if (durasi == "1 jam" || durasi == "2 jam" || durasi == "3 jam" || durasi == "4 jam" ||durasi == "5 jam" || durasi == "6 jam") {
                bool dataExists = await checkIfDataExist(name);
                if (dataExists) {
                  setState(() {
                    _isSaving = false;
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Anda tidak dapat mengajukan lembur karena sudah tersimpan sebelumnya'),
                      backgroundColor: Colors.blueAccent,
                    ));
                  }
                  return;
                }

                int docCustom =
                    3000000000000 - DateTime.now().millisecondsSinceEpoch;
                String docId = docCustom.toString();
                DocumentReference documentReference = _karyawan.doc(docId);

                await documentReference.set({
                  "alasan": alasan,
                  "name": name,
                  "timestamps": FieldValue.serverTimestamp(),
                  "durasi": durasi,
                  "status": status,
                });

                setState(() {
                  _isSaving = false;
                });

                _nameController.text = '';
                _alasanController.text='';

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Pengajuan anda berhasil terkirim'),
                    backgroundColor: Colors.blueAccent,
                  ));
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const Bottom()));
                }
              } else {
                setState(() {
                  _isSaving = false;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Masukkan Durasi Lembur'),
                    backgroundColor: Colors.blueAccent,
                  ));
                }
              }
            },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xFF1A73E8),
        ),
        width: 120,
        height: 50,
        child: _isSaving
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              )
            : const Text(
                'Simpan',
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
        decoration: const InputDecoration(
          labelText: 'Nama',
          labelStyle: TextStyle(
            color: Colors.blueAccent,
            fontFamily: "Source Sans Pro",
          ),
          border: OutlineInputBorder(),
        ),
        style: const TextStyle(
          color: Colors.blueAccent,
          fontSize: 18,
          fontFamily: "Source Sans Pro",
        ),
        enabled: false,
      ),
    );
  }

  Padding alasan() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextFormField(
        controller: _alasanController,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Alasan Lembur',
          labelStyle: TextStyle(
            color: Colors.blueAccent,
            fontFamily: "Source Sans Pro",
          ),
          border: OutlineInputBorder(),
        ),
        style: const TextStyle(
          color: Colors.blueAccent,
          fontSize: 18,
          fontFamily: "Source Sans Pro",
        ),
      ),
    );
  }

  Padding durasi() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            width: 0.5,
            color: const Color(0xffC5C5C5),
          ),
        ),
        child: DropdownButton<String>(
          value: _selectedDurasi,
          onChanged: ((value) {
            setState(() {
              _selectedDurasi = value;
            });
          }),
          items: listOfDurasi
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Container(
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          Text(
                            e,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.blueAccent,
                              fontFamily: "Source Sans Pro",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
          selectedItemBuilder: (BuildContext context) => listOfDurasi
              .map((e) => Row(
                    children: [
                      Text(
                        e,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.blueAccent,
                          fontFamily: "Source Sans Pro",
                        ),
                      ),
                    ],
                  ))
              .toList(),
          hint: const Padding(
            padding: EdgeInsets.only(left: 1),
            child: Text(
              'Pilih Durasi Lembur',
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
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                      const Text(
                        'Form Pengajuan Lembur',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    const Icon(
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
  Future<bool> checkIfDataExist(String name) async {
    final DateTime now = DateTime.now();

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('lemburs')
        .where('name', isEqualTo: name)
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
}
