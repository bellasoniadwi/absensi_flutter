import 'package:absensi_flutter/auth/signin_screen.dart';
import 'package:absensi_flutter/models/user_data.dart';
import 'package:absensi_flutter/screens/riwayat.dart';
import 'package:absensi_flutter/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
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
  final PageController _pageController = PageController(initialPage: 0);
  bool firstPage = true;
  NotificationsServices notificationsServices = NotificationsServices();
  final logger = Logger();

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
    notificationsServices.initializeNotifications();
    notificationsServices.scheduleNotification();
    _scheduleAutomaticNotifications();
  }

  void _scheduleAutomaticNotifications() {
    notificationsServices.scheduleNotification();
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
          String name = userDoc.data()?['name'] ?? 'Guest';
          String email = userDoc.data()?['email'] ?? 'guest@example.com';
          String jabatan = userDoc.data()?['jabatan'] ?? 'Jabatan';
          String image = userDoc.data()?['image'] ??
              'https://img.freepik.com/free-icon/user_318-159711.jpg';
          String nomorInduk = userDoc.data()?['nomor_induk'] ?? 'Nomor Induk';
          String telepon = userDoc.data()?['telepon'] ?? 'Telepon';
          if (mounted) {
            Provider.of<UserData>(context, listen: false).updateUserData(
                name, email, jabatan, image, nomorInduk, telepon);
          }

          setState(() {
            _userName = userDoc.data()?['name'] ?? 'Guest';
          });
        }
      }
    } catch (error) {
      logger.e("Error fetching user data: $error");
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

      totalTepatWaktuDatang = countEntriesWithinMonthYear(
          tepatWaktuDatangSnapshot.docs, now.year, now.month);
      totalTerlambatDatang = countEntriesWithinMonthYear(
          telatDatangSnapshot.docs, now.year, now.month);
      totalIzinDatang = countEntriesWithinMonthYear(
          izinDatangSnapshot.docs, now.year, now.month);
      totalPulangBiasa = countEntriesWithinMonthYear(
          pulangBiasaSnapshot.docs, now.year, now.month);
      totalLembur = countEntriesWithinMonthYear(
          pulangLemburSnapshot.docs, now.year, now.month);
      totalIzinPulang = countEntriesWithinMonthYear(
          izinPulangSnapshot.docs, now.year, now.month);

      setState(() {});
    } catch (error) {
      logger.e("Error fetching : $error");
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
                          const Text(
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
                                      builder: (context) => const RiwayatAbsen()));
                            },
                            child: const Text(
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
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            _getFormattedTimestamp(
                                documentSnapshot['timestamps']),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                documentSnapshot['kategori'],
                                style: const TextStyle(
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
              decoration: const BoxDecoration(
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
                            const Text(
                              'Welcome,',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: Color.fromARGB(255, 224, 223, 223),
                              ),
                            ),
                            Text(
                              accountName,
                              style: const TextStyle(
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
                                color: const Color.fromRGBO(250, 250, 250, 0.1),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.logout,
                                    color: Colors.white,
                                  ),
                                  onPressed: () async {
                                    await FirebaseAuth.instance.signOut();
                                    final SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    prefs.remove('isLoggedIn');
                                    logger.e("Signed Out");
                                    if (mounted) {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const SignInScreen()));
                                    }
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
            width: 320,
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 107, 181, 242),
                  offset: Offset(0, 6),
                  blurRadius: 12,
                  spreadRadius: 6,
                ),
              ],
              color: Color(0xFF1A73E8),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
            ),
            ),
            child: firstPage ? rekapDatang() : rekapPulang(),
          ),
        ),
      ],
    );
  }

  Widget rekapDatang() {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
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
        const SizedBox(height: 7),
        Padding(
          padding: const EdgeInsets.only(left: 11, right: 11),
          child: Text(
            'Rekapitulasi Kedatangan ${DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now())}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(right: 15, left: 15, bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildArrowBack(),
              _buildRekapColumn(
                FontAwesomeIcons.thumbsUp,
                'Tepat Waktu',
                '$totalTepatWaktuDatang Hari',
              ),
              _buildRekapColumn(
                FontAwesomeIcons.handshake,
                'Izin',
                '$totalIzinDatang Hari',
              ),
              _buildRekapColumn(
                FontAwesomeIcons.thumbsDown,
                'Terlambat',
                '$totalTerlambatDatang Hari',
              ),
              _buildArrowForward(),
            ],
          ),
        ),
      ],
    );
  }

  Widget rekapPulang() {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
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
        const SizedBox(height: 7),
        Padding(
          padding: const EdgeInsets.only(left: 11, right: 11),
          child: Text(
            'Rekapitulasi Kepulangan ${DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now())}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(right: 15, left: 15, bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildArrowBack(),
              _buildRekapColumn(
                FontAwesomeIcons.thumbsUp,
                'Normal',
                '$totalPulangBiasa Hari',
              ),
              _buildRekapColumn(
                FontAwesomeIcons.handshake,
                'Izin',
                '$totalIzinPulang Hari',
              ),
              _buildRekapColumn(
                FontAwesomeIcons.star,
                'Lembur',
                '$totalLembur Hari',
              ),
              _buildArrowForward()
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArrowBack() {
    return Column(
      children: [
        GestureDetector(
          child: Stack(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      spreadRadius: 3,
                      blurRadius: 9,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const Icon(
                FontAwesomeIcons.chevronLeft,
                color: Colors.white,
                size: 25,
              ),
            ],
          ),
          onTap: () {
            setState(() {
              firstPage = !firstPage;
            });
          },
        ),
        const SizedBox(height: 7),
        const Text(
          "",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Color.fromARGB(255, 216, 216, 216),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildArrowForward() {
    return Column(
      children: [
        GestureDetector(
          child: Stack(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      spreadRadius: 3,
                      blurRadius: 9,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const Icon(
                FontAwesomeIcons.chevronRight,
                color: Colors.white,
                size: 25,
              ),
            ],
          ),
          onTap: () {
            setState(() {
              firstPage = !firstPage;
            });
          },
        ),
        const SizedBox(height: 7),
        const Text(
          "",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Color.fromARGB(255, 216, 216, 216),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildRekapColumn(IconData icon, String title, String value) {
    return Column(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: Colors.white,
          child: Icon(
            icon,
            color: const Color(0xFF1A73E8),
            size: 18,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Color.fromARGB(255, 216, 216, 216),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Colors.white,
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
      return 'No Timestamp';
    }
    DateTime dateTime = timestamp.toDate();
    String formattedDateTime =
        DateFormat('dd-MM-yyyy HH:mm:ss').format(dateTime);
    return formattedDateTime;
  }
}
