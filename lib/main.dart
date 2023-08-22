import 'package:absensi_flutter/auth/signin_screen.dart';
import 'package:absensi_flutter/models/user_data.dart';
import 'package:flutter/material.dart';
import 'package:absensi_flutter/widgets/bottomnavigationbar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/model/add_date.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  Hive.registerAdapter(AdddataAdapter());
  await Hive.openBox<Add_data>('data');
  final bool isLoggedIn = await checkLoggedInStatus();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserData()),
      ], 
      child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? Bottom() : SignInScreen(),
    )
    );
  }
}

Future<bool> checkLoggedInStatus() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}
