import 'package:absensi_flutter/screens/form_lembur.dart';
import 'package:absensi_flutter/screens/list_lemburs.dart';
import 'package:absensi_flutter/screens/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:absensi_flutter/screens/add.dart';
import 'package:absensi_flutter/screens/home.dart';

class Bottom extends StatefulWidget {
  const Bottom({Key? key}) : super(key: key);

  @override
  State<Bottom> createState() => _BottomState();
}

class _BottomState extends State<Bottom> {
  int indexColor = 0;
  List screen = [const Home(), const FormLembur(), const RiwayatLembur(), const ProfilePage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screen[indexColor],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => const AddScreen()));
        },
        backgroundColor: const Color(0xFF1A73E8),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.only(top: 7.5, bottom: 7.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    indexColor = 0;
                  });
                },
                child: Icon(
                  Icons.home,
                  size: 30,
                  color: indexColor == 0 ? const Color(0xFF1A73E8) : Colors.grey,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    indexColor = 1;
                  });
                },
                child: Icon(
                  Icons.edit,
                  size: 30,
                  color: indexColor == 1 ? const Color(0xFF1A73E8) : Colors.grey,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  setState(() {
                    indexColor = 2;
                  });
                },
                child: Icon(
                  Icons.list,
                  size: 30,
                  color: indexColor == 2 ? const Color(0xFF1A73E8) : Colors.grey,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    try {
                      var userDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .get();
                      if (userDoc.exists) {
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfilePage(documentSnapshot: userDoc),
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User data not found')),
                          );
                        }
                      }
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Error fetching user data: $error')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User not logged in')),
                    );
                  }
                },
                child: Icon(
                  Icons.person_outlined,
                  size: 30,
                  color: indexColor == 3 ? const Color(0xFF1A73E8) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
