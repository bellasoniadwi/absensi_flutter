import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserData extends ChangeNotifier {
  String? name;
  String? email;
  String? jabatan;
  String? image;
  String? nomor_induk;
  String? telepon;
  

  // Metode untuk memuat data pengguna dari Firestore berdasarkan UID
  Future<void> fetchUserData(String uid) async {
    try {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        name = userDoc.data()?['name'];
        email = userDoc.data()?['email'];
        jabatan = userDoc.data()?['jabatan'];
        image = userDoc.data()?['image'];
        nomor_induk = userDoc.data()?['nomor_induk'];
        telepon = userDoc.data()?['telepon'];
        
        notifyListeners();
      }
    } catch (error) {
      print("Error fetching user data: $error");
    }
  }
  
  // Metode untuk memperbarui data pengguna
  void updateUserData(String newName, String newEmail, String newJabatan, String newImage, String newNomorinduk, String newTelepon) {
    name = newName;
    email = newEmail;
    jabatan = newJabatan;
    image = newImage;
    nomor_induk = newNomorinduk;
    telepon = newTelepon;
    notifyListeners();
  }
}
