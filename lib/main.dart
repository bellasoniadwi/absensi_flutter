import 'package:absensi_flutter/auth/signin_screen.dart';
import 'package:absensi_flutter/models/user_data.dart';
import 'package:flutter/material.dart';
import 'package:absensi_flutter/widgets/bottomnavigationbar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final bool isLoggedIn = await checkLoggedInStatus();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn; 
  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserData()),
      ], 
      child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const Bottom() : const SignInScreen(),
    )
    );
  }
}

Future<bool> checkLoggedInStatus() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}
