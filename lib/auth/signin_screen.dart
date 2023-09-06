import 'package:absensi_flutter/widgets/bottomnavigationbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:absensi_flutter/auth/reset_password.dart';
import 'package:absensi_flutter/reusable_item/color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absensi_flutter/models/user_data.dart';
import 'package:absensi_flutter/reusable_item/widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
            hexStringToColor("3389FF"),
            hexStringToColor("#5F96E2"),
            hexStringToColor("104FA6")
        ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SingleChildScrollView(
            child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).size.height * 0.2, 20, 0),
          child: Column(children: <Widget>[
            logoWidget("images/logo1.png"),
            SizedBox(
              height: 30,
            ),
            reusableTextField(
              "Masukkan Email Anda",
              Icons.mail,
              controller: _emailTextController,
            ),
            SizedBox(
              height: 30,
            ),
            reusableTextField(
              "Masukkan Password Anda",
              Icons.lock_outlined,
              isPasswordType: true,
              isPasswordVisible: _isPasswordVisible,
              controller: _passwordTextController,
              onTogglePasswordVisibility: (isVisible) {
                setState(() {
                  _isPasswordVisible = isVisible;
                });
              },
            ),
            SizedBox(
              height: 30,
            ),
            AuthButton(context, true, _isLoading, () async {
              setState(() {
                _isLoading = true; // Set loading state to true
              });

              try {
                final UserCredential userCredential =
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: _emailTextController.text,
                        password: _passwordTextController.text);

                final String uid = userCredential.user?.uid ?? '';

                var userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get();
                if (userDoc.exists) {
                  String role = userDoc.data()?['role'] ?? '';
                  bool isblocking = userDoc.data()?['isblocking'] ?? '';
                  
                  if (role == 'Karyawan' && isblocking == false) {
                    String jabatan = userDoc.data()?['jabatan'] ?? '';
                    String image = userDoc.data()?['image'] ?? '';
                    String nomor_induk = userDoc.data()?['nomor_induk'] ?? '';
                    String telepon = userDoc.data()?['telepon'] ?? '';
                    Provider.of<UserData>(context, listen: false)
                        .updateUserData(
                            userCredential.user?.displayName ?? "Guest",
                            userCredential.user?.email ?? "guest@example.com",
                            jabatan,
                            image,
                            nomor_induk,
                            telepon);

                    // Set status login sebagai true saat pengguna berhasil login
                    final SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    prefs.setBool('isLoggedIn', true);

                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => Bottom()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Anda tidak diperkenankan untuk login. Mohon untuk menghubungi admin.'),
                            backgroundColor: Colors.blueAccent,));
                  }
                }
              } catch (error) {
                print("Authentication Error: ${error.toString()}");
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid Email or Password'),
                    backgroundColor: Colors.blueAccent,));
              } finally {
                setState(() {
                  _isLoading = false; // Set loading state back to false
                });
              }
            }),
            SizedBox(
              height: 15,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) {
                          return ResetPassword();
                        },
                        )
                      );
                    },
                    child: const Text(
                      "Lupa password?",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          ]),
        )),
      ),
    );
  }
}
