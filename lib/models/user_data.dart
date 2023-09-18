import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class UserData extends ChangeNotifier {
  String? name;
  String? email;
  String? jabatan;
  String? image;
  String? nomorInduk;
  String? telepon;
  final logger = Logger();
  

  // Metode untuk memuat data pengguna dari Firestore berdasarkan UID
  Future<void> fetchUserData(String uid) async {
    try {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        name = userDoc.data()?['name'];
        email = userDoc.data()?['email'];
        jabatan = userDoc.data()?['jabatan'];
        image = userDoc.data()?['image'];
        nomorInduk = userDoc.data()?['nomor_induk'];
        telepon = userDoc.data()?['telepon'];
        
        notifyListeners();
      }
    } catch (error) {
      logger.e("Error fetching user data: $error");
    }
  }
  
  // Metode untuk memperbarui data pengguna
  void updateUserData(String newName, String newEmail, String newJabatan, String newImage, String newNomorinduk, String newTelepon) {
    name = newName;
    email = newEmail;
    jabatan = newJabatan;
    image = newImage;
    nomorInduk = newNomorinduk;
    telepon = newTelepon;
    notifyListeners();
  }
}
