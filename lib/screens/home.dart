import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:absensi_flutter/data/listdata.dart';
import 'package:absensi_flutter/data/model/add_date.dart';
import 'package:absensi_flutter/data/utlity.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: _karyawan.snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
            if (streamSnapshot.hasData) {
              return SafeArea(
                  child: ValueListenableBuilder(
                      valueListenable: box.listenable(),
                      builder: (context, value, child) {
                        return CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: SizedBox(height: 340, child: _header()),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
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
                                    Text(
                                      'See all',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final reversedIndex =
                                      streamSnapshot.data!.docs.length -
                                          1 -
                                          index;
                                  final DocumentSnapshot documentSnapshot =
                                      streamSnapshot.data!.docs[reversedIndex];

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
                                            color: documentSnapshot[
                                                        'keterangan'] ==
                                                    'Masuk'
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ));
                                },
                                childCount: streamSnapshot.data!.docs.length,
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
                        child: Icon(
                          Icons.logout,
                          size: 30,
                          color: Colors.white,
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
                          'Enjelin Morgeana',
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
            height: 170,
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
            child: Column(
              children: [
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Balance',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Icon(
                        Icons.more_horiz,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 7),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Row(
                    children: [
                      Text(
                        '\$ ${total()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.arrow_downward,
                              color: Colors.blue,
                              size: 19,
                            ),
                          ),
                          SizedBox(width: 7),
                          Text(
                            'Income',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: Color.fromARGB(255, 216, 216, 216),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.arrow_upward,
                              color: Colors.blue,
                              size: 19,
                            ),
                          ),
                          SizedBox(width: 7),
                          Text(
                            'Expenses',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: Color.fromARGB(255, 216, 216, 216),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$ ${income()}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '\$ ${expenses()}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        )
      ],
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
}
