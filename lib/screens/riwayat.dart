import 'package:absensi_flutter/widgets/bottomnavigationbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class RiwayatAbsen extends StatefulWidget {
  const RiwayatAbsen({Key? key}) : super(key: key);

  @override
  RiwayatAbsenState createState() => RiwayatAbsenState();
}

class RiwayatAbsenState extends State<RiwayatAbsen> {
  final CollectionReference _karyawan =
      FirebaseFirestore.instance.collection('karyawans');
  DateTime selectedDate = DateTime.now();
  String imageUrl = '';
  String? _userName;
  final logger = Logger();

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
          setState(() {
            _userName = userDoc.data()?['name'] ?? 'Guest';
          });
        }
      }
    } catch (error) {
      logger.e("Error fetching user data: $error");
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
                        const IntrinsicHeight(
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
                                              style: const TextStyle(
                                                fontSize: 18,
                                                letterSpacing: 2.5,
                                                fontWeight: FontWeight.bold)),
                                              Text(
                                                _getFormattedTimestamp(
                                                    documentSnapshot[
                                                        'timestamps']),
                                                style: const TextStyle(
                                                fontSize: 15,
                                                letterSpacing: 1)
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    '\n${documentSnapshot['keterangan']}',
                                                    style: TextStyle(
                                                    fontSize: 15,
                                                    letterSpacing: 1,
                                                    color: getKeteranganColor(
                                                      documentSnapshot['keterangan'],
                                                    ),)
                                                  ),
                                                  const Text(
                                                        '\n  -  ',
                                                    style: TextStyle(
                                                    fontSize: 15,
                                                    letterSpacing: 1,)
                                                  ),
                                                  Text(
                                                    '\n${documentSnapshot['status']}',
                                                    style: TextStyle(
                                                    fontSize: 15,
                                                    letterSpacing: 1,
                                                    color: getStatusColor(
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
                                              60,
                                          height:
                                              80,
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
                        MaterialPageRoute(builder: (context) => const Bottom()))
                    .then((data) {});
              },
              backgroundColor: Colors.blueAccent,
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
      ),
    );
  }

  String _getFormattedTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'No Timestamp';
    }
    DateTime dateTime = timestamp.toDate();
    String formattedDateTime =
        DateFormat('dd-MM-yyyy HH:mm:ss').format(dateTime);
    return formattedDateTime;
  }

  Color getKeteranganColor(String keterangan) {
    if (keterangan == 'Masuk') {
      return Colors.green;
    } else if (keterangan == 'Izin') {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color getStatusColor(String status) {
    if (status == 'Tepat Waktu') {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }
}
