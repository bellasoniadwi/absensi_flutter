import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RiwayatLembur extends StatefulWidget {
  const RiwayatLembur({Key? key}) : super(key: key);

  @override
  _RiwayatLemburState createState() => _RiwayatLemburState();
}

class _RiwayatLemburState extends State<RiwayatLembur> {
  final CollectionReference _lembur =
      FirebaseFirestore.instance.collection('lemburs');
  DateTime selectedDate = DateTime.now();
  String? _userName;

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
      print("Error fetching user data: $error");
    }
  }

  Future<void> _deleteLembur(String lemburId) async {
    await _lembur.doc(lemburId).delete();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pengajuan lembur anda berhasil dihapus'), backgroundColor: Colors.blueAccent,));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: StreamBuilder(
            stream: _lembur.where('name', isEqualTo: _userName).snapshots(),
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
                                child: Text('Pengajuan Lembur',
                                    style: TextStyle(
                                        fontSize: 30,
                                        letterSpacing: 2.5,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "Source Sans Pro")),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
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
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              Text(
                                                  _getFormattedTimestamp(
                                                      documentSnapshot[
                                                          'timestamps']),
                                                  style: TextStyle(
                                                      fontSize: 15,
                                                      letterSpacing: 1)),
                                              Row(
                                                children: [
                                                  Text(
                                                      '\n' +
                                                          _getFormattedStatus(documentSnapshot['status']),
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        letterSpacing: 1,
                                                        color: getStatusColor(
                                                          documentSnapshot[
                                                              'status'],
                                                        ),
                                                      )),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 5,
                                              ),
                                            ],
                                          ),
                                        ),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red,),
                                            onPressed: () => _deleteLembur(documentSnapshot.id),
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
      ),
    );
  }

  String _getFormattedTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'No Timestamp';
    }
    DateTime dateTime = timestamp.toDate();
    String formattedDateTime = DateFormat('EEEE, d MMMM y', 'id_ID').format(dateTime);
    return formattedDateTime;
  }

  String _getFormattedStatus(bool? status) {
    String keputusan = '';
    if (status == true) {
      keputusan = 'Disetujui';
    } else {
      keputusan = 'Menunggu';
    }
    return keputusan;
  }

  Color getStatusColor(bool status) {
    if (status == true) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }
}
