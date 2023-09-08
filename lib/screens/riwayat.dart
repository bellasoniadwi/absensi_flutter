import 'package:absensi_flutter/widgets/bottomnavigationbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RiwayatAbsen extends StatefulWidget {
  const RiwayatAbsen({Key? key}) : super(key: key);

  @override
  _RiwayatAbsenState createState() => _RiwayatAbsenState();
}

class _RiwayatAbsenState extends State<RiwayatAbsen> {
  // Mendefinisikan variabel
  final CollectionReference _karyawan =
      FirebaseFirestore.instance.collection('karyawans');
  DateTime selectedDate = DateTime.now();
  String imageUrl = '';
  String? _userName;

  void initState() {
    super.initState();
    fetchUserDataFromFirestore();
  }

  Future<void> fetchUserDataFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Ambil data pengguna dari Firestore berdasarkan UID
        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            _userName = userDoc.data()?['name'] ?? 'Guest';
          });
        }
      }
    } catch (error) {
      print("Error fetching user data: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: StreamBuilder(
            stream: _karyawan
              .where('name', isEqualTo: _userName)
              .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
              if (streamSnapshot.hasData) {
                return SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IntrinsicHeight(
                          child: Stack(
                            children: [
                              Align(
                                child: Text(
                                  'Riwayat Absensi',
                                  style: TextStyle(
                                    fontSize: 30,
                                    letterSpacing: 2.5,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "Source Sans Pro")
                                ),
                              ),
                              
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: streamSnapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final DocumentSnapshot documentSnapshot =
                                  streamSnapshot.data!.docs[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.white,
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Text(documentSnapshot['name'],
                                              style: TextStyle(
                                                fontSize: 18,
                                                letterSpacing: 2.5,
                                                fontWeight: FontWeight.bold)),
                                              Text(
                                                _getFormattedTimestamp(
                                                    documentSnapshot[
                                                        'timestamps']),
                                                style: TextStyle(
                                                fontSize: 15,
                                                letterSpacing: 1)
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                        '\n'+documentSnapshot[
                                                            'keterangan'],
                                                    style: TextStyle(
                                                    fontSize: 15,
                                                    letterSpacing: 1,
                                                    color: getStatusColor(
                                                      documentSnapshot['keterangan'],
                                                    ),)
                                                  ),
                                                  Text(
                                                        '\n  -  ',
                                                    style: TextStyle(
                                                    fontSize: 15,
                                                    letterSpacing: 1,)
                                                  ),
                                                  Text(
                                                        '\n'+documentSnapshot[
                                                            'status'],
                                                    style: TextStyle(
                                                    fontSize: 15,
                                                    letterSpacing: 1,
                                                    color: getStatusColorStatus(
                                                      documentSnapshot['status'],
                                                    ),)
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 5,
                                              ),
                                            ],
                                          ),
                                        ),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                          documentSnapshot['image'],
                                          width:
                                              60, // Sesuaikan ukuran gambar sesuai kebutuhan Anda
                                          height:
                                              80, // Sesuaikan ukuran gambar sesuai kebutuhan Anda
                                          fit: BoxFit.cover,
                                        ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const Center(
                child: CircularProgressIndicator(),
              );
            }),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(context,
                        MaterialPageRoute(builder: (context) => Bottom()))
                    .then((data) {});
              },
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              backgroundColor: Colors.blueAccent,
            ),
      ),
    );
  }

  String _getFormattedTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      // Handle the case when 'timestamps' is null, set a default value or return an empty string
      return 'No Timestamp';
    }
    // Convert the Timestamp to DateTime
    DateTime dateTime = timestamp.toDate();
    // Format the DateTime as a human-readable string (change the format as desired)
    String formattedDateTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    return formattedDateTime;
  }

  Color getStatusColor(String keterangan) {
    if (keterangan == 'Masuk') {
      return Colors.green;
    } else if (keterangan == 'Izin') {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color getStatusColorStatus(String status) {
    if (status == 'Tepat Waktu') {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }
}
