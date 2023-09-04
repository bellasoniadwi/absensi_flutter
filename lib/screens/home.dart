import 'package:absensi_flutter/auth/signin_screen.dart';
import 'package:absensi_flutter/models/user_data.dart';
import 'package:absensi_flutter/screens/riwayat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:absensi_flutter/data/utlity.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final CollectionReference _karyawan =
      FirebaseFirestore.instance.collection('karyawans');
  DateTime selectedDate = DateTime.now();
  String imageUrl = '';
  String? _userName;
  int totalMasuk = 0;
  int totalIzin = 0;
  int totalSakit = 0;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting("id_ID", null);
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
          String name = userDoc.data()?['name'] ?? 'Guest';
          String email = userDoc.data()?['email'] ?? 'guest@example.com';
          String jabatan = userDoc.data()?['jabatan'] ?? 'Jabatan';
          String image = userDoc.data()?['image'] ??
              'https://img.freepik.com/free-icon/user_318-159711.jpg';
          String nomor_induk = userDoc.data()?['nomor_induk'] ?? 'Nomor Induk';
          String telepon = userDoc.data()?['telepon'] ?? 'Telepon';

          Provider.of<UserData>(context, listen: false).updateUserData(
              name, email, jabatan, image, nomor_induk, telepon);

          setState(() {
            _userName = userDoc.data()?['name'] ?? 'Guest';
          });
        }
      }
    } catch (error) {
      print("Error fetching user data: $error");
    }
  }

  Future<void> fetchTotalAbsensi() async {
    try {
      final DateTime now = DateTime.now();

      final QuerySnapshot masukSnapshot = await _karyawan
          .where('name', isEqualTo: _userName)
          .where('keterangan', isEqualTo: 'Masuk')
          .get();

      final QuerySnapshot izinSnapshot = await _karyawan
          .where('name', isEqualTo: _userName)
          .where('keterangan', isEqualTo: 'Izin')
          .get();

      final QuerySnapshot sakitSnapshot = await _karyawan
          .where('name', isEqualTo: _userName)
          .where('keterangan', isEqualTo: 'Sakit')
          .get();

      totalMasuk =
          countEntriesWithinMonthYear(masukSnapshot.docs, now.year, now.month);
      totalIzin =
          countEntriesWithinMonthYear(izinSnapshot.docs, now.year, now.month);
      totalSakit =
          countEntriesWithinMonthYear(sakitSnapshot.docs, now.year, now.month);

      setState(() {});
    } catch (error) {
      print("Error fetching : $error");
    }
  }

  // mengubah format timestamps menjadi datetime
  int countEntriesWithinMonthYear(
      List<QueryDocumentSnapshot> documents, int year, int month) {
    int count = 0;
    for (var doc in documents) {
      DateTime docTimestamp = (doc['timestamps'] as Timestamp).toDate();
      if (docTimestamp.year == year && docTimestamp.month == month) {
        count++;
      }
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: _karyawan.where('name', isEqualTo: _userName).snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
            if (streamSnapshot.hasData) {
              fetchTotalAbsensi();
              return SafeArea(
                  child: ValueListenableBuilder(
                      valueListenable: box.listenable(),
                      builder: (context, value, child) {
                        return CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: SizedBox(height: 370, child: _header()),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 15, right: 15, bottom: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Riwayat Absensi',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 19,
                                        color: Colors.black,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    RiwayatAbsen()));
                                      },
                                      child: Text(
                                        'Lihat semua',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final DocumentSnapshot documentSnapshot =
                                      streamSnapshot.data!.docs[index];

                                  return Dismissible(
                                      key: UniqueKey(),
                                      onDismissed: (direction) {},
                                      child: ListTile(
                                        leading: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Image.network(
                                            documentSnapshot['image'],
                                            width: 60,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        title: Text(
                                          documentSnapshot['name'],
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          _getFormattedTimestamp(
                                              documentSnapshot['timestamps']),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        trailing: Text(
                                          documentSnapshot['keterangan'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 19,
                                            color: getStatusColor(
                                              documentSnapshot['keterangan'],
                                            ),
                                          ),
                                        ),
                                      ));
                                },
                                childCount: getNumberLength(
                                    streamSnapshot.data!.docs.length),
                              ),
                            )
                          ],
                        );
                      }));
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          }),
    );
  }

  Widget _header() {
    final userData = Provider.of<UserData>(context);
    // Dapatkan data Nama dan Email dari variabel global
    final String accountName = userData.name ?? 'Guest';
    return Stack(
      children: [
        Column(
          children: [
            Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 35,
                    left: 340,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        height: 40,
                        width: 40,
                        color: Color.fromRGBO(250, 250, 250, 0.1),
                        child: IconButton(
                          icon: Icon(
                            Icons.logout,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            final SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            prefs.remove(
                                'isLoggedIn'); // Hapus status login saat logout
                            print("Signed Out");
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SignInScreen()));
                          },
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 35, left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome,',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Color.fromARGB(255, 224, 223, 223),
                          ),
                        ),
                        Text(
                          '$accountName',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
        Positioned(
          top: 140,
          left: 37,
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 107, 181, 242),
                  offset: Offset(0, 6),
                  blurRadius: 12,
                  spreadRadius: 6,
                ),
              ],
              color: Color(0xFF1A73E8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: SingleChildScrollView(
              // Tambahkan widget SingleChildScrollView di sini
              child: Column(
                children: [
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 8,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 7),
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Text(
                      'Rekapitulasi Absensi ${DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now())}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding:
                        const EdgeInsets.only(right: 15, left: 15, bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              CircleAvatar(
                                  radius: 13,
                                  backgroundColor: Colors.white,
                                  child: Image.asset('images/m.png')),
                              SizedBox(height: 7),
                              Text(
                                'Masuk',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 216, 216, 216),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                '$totalMasuk Hari',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              CircleAvatar(
                                  radius: 13,
                                  backgroundColor: Colors.white,
                                  child: Image.asset('images/i.png')),
                              SizedBox(height: 7),
                              Text(
                                'Izin',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 216, 216, 216),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                '$totalIzin Hari',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              CircleAvatar(
                                  radius: 13,
                                  backgroundColor: Colors.white,
                                  child: Image.asset('images/s.png')),
                              SizedBox(height: 7),
                              Text(
                                'Sakit',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 216, 216, 216),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                '$totalSakit Hari',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
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

  int getNumberLength(int length) {
    if (length >= 3) {
      return 3;
    } else {
      return length;
    }
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
        DateFormat('dd-MM-yyyy HH:mm:ss').format(dateTime);
    return formattedDateTime;
  }
}
