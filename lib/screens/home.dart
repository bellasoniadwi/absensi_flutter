import 'package:absensi_flutter/auth/signin_screen.dart';
import 'package:absensi_flutter/models/user_data.dart';
import 'package:absensi_flutter/screens/riwayat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  int totalTepatWaktuDatang = 0;
  int totalTerlambatDatang = 0;
  int totalIzinDatang = 0;
  int totalPulangBiasa = 0;
  int totalLembur = 0;
  int totalIzinPulang = 0;
  PageController _pageController = PageController(initialPage: 0);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

      final QuerySnapshot tepatWaktuDatangSnapshot = await _karyawan
          .where('name', isEqualTo: _userName)
          .where('keterangan', isEqualTo: 'Masuk')
          .where('status', isEqualTo: 'Tepat Waktu')
          .where('kategori', isEqualTo: 'Datang')
          .get();

      final QuerySnapshot telatDatangSnapshot = await _karyawan
          .where('name', isEqualTo: _userName)
          .where('keterangan', isEqualTo: 'Masuk')
          .where('status', isEqualTo: 'Terlambat')
          .where('kategori', isEqualTo: 'Datang')
          .get();

      final QuerySnapshot izinDatangSnapshot = await _karyawan
          .where('name', isEqualTo: _userName)
          .where('keterangan', isEqualTo: 'Izin')
          .where('kategori', isEqualTo: 'Datang')
          .get();

      final QuerySnapshot izinPulangSnapshot = await _karyawan
          .where('name', isEqualTo: _userName)
          .where('keterangan', isEqualTo: 'Izin')
          .where('kategori', isEqualTo: 'Pulang')
          .get();

      final QuerySnapshot pulangBiasaSnapshot = await _karyawan
          .where('name', isEqualTo: _userName)
          .where('keterangan', isEqualTo: 'Tidak Lembur')
          .where('kategori', isEqualTo: 'Pulang')
          .get();

      final QuerySnapshot pulangLemburSnapshot = await _karyawan
          .where('name', isEqualTo: _userName)
          .where('keterangan', isEqualTo: 'Lembur')
          .where('kategori', isEqualTo: 'Pulang')
          .get();

      totalTepatWaktuDatang = countEntriesWithinMonthYear(tepatWaktuDatangSnapshot.docs, now.year, now.month);
      totalTerlambatDatang = countEntriesWithinMonthYear(telatDatangSnapshot.docs, now.year, now.month);
      totalIzinDatang = countEntriesWithinMonthYear(izinDatangSnapshot.docs, now.year, now.month);
      totalPulangBiasa = countEntriesWithinMonthYear(pulangBiasaSnapshot.docs, now.year, now.month);
      totalLembur = countEntriesWithinMonthYear(pulangLemburSnapshot.docs, now.year, now.month);
      totalIzinPulang = countEntriesWithinMonthYear(izinPulangSnapshot.docs, now.year, now.month);

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
                  child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(height: 370, child: _header()),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 15, right: 15, bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      builder: (context) => RiwayatAbsen()));
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
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
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
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                documentSnapshot['kategori'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                documentSnapshot['status'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                  color: getStatusColor(
                                    documentSnapshot['status'],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount:
                          getNumberLength(streamSnapshot.data!.docs.length),
                    ),
                  )
                ],
              ));
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 35, left: 10, right: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
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
                                    prefs.remove('isLoggedIn');
                                    print("Signed Out");
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                SignInScreen()));
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          top: 140,
          left: 37,
          right: 37,
          child: Container(
            height: 200,
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
            child: GestureDetector(
            onHorizontalDragEnd: (DragEndDetails details) {
              if (details.primaryVelocity! > 0) {
                _pageController.previousPage(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              } else {
                _pageController.nextPage(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                rekap_datang(),
                rekap_pulang(),
              ],
            ),
          ),
          ),
        )
      ],
    );
  }

  Widget rekap_datang() {
    return Column(
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
          padding: const EdgeInsets.only(left: 11, right: 11),
          child: Text(
            'Rekapitulasi Kedatangan ${DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now())}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 15, left: 15, bottom: 20),
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
                        'Tepat Waktu',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Color.fromARGB(255, 216, 216, 216),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '$totalTepatWaktuDatang Hari',
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
                        'Terlambat',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Color.fromARGB(255, 216, 216, 216),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '$totalTerlambatDatang Hari',
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
                        'Izin',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Color.fromARGB(255, 216, 216, 216),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '$totalIzinDatang Hari',
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
        ),
      ],
    );
  }

  Widget rekap_pulang() {
    return Column(
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
          padding: const EdgeInsets.only(left: 11, right: 11),
          child: Text(
            'Rekapitulasi Kepulangan ${DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now())}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(right: 15, left: 15, bottom: 20),
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
                      'Normal',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Color.fromARGB(255, 216, 216, 216),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '$totalPulangBiasa Hari',
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
                      '$totalIzinPulang Hari',
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
                      'Lembur',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Color.fromARGB(255, 216, 216, 216),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '$totalLembur Hari',
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
    );
  }
  

  Color getStatusColor(String status) {
    if (status == 'Tepat Waktu') {
      return Colors.blue;
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
