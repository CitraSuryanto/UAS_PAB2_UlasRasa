import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reviewrestopab2/pages/addResto.dart';
import 'package:reviewrestopab2/pages/homepage.dart';
import 'package:reviewrestopab2/pages/login.dart';
import 'package:reviewrestopab2/pages/register.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.white,
          secondary: Colors.black,
        ),
        useMaterial3: true,
      ),
      home: AuthWrapper(),
      routes: {
    '/home': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
    return HomePage(
    userRole: args['userRole'] ?? '',
    userId: args['userId'] ?? '',
    userName: args['userName'] ?? '',
    );
    },
        '/register': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(),
        '/addHotel' : (context) => AddRestoPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.userChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          String userId = snapshot.data!.uid;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('profile').doc(userId).get(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
                String role = roleSnapshot.data!['role'];
                String name = roleSnapshot.data!['name'] ?? 'Pengguna';
                return HomePage(userRole: role, userId: userId, userName: name);
              } else {
                return const LoginPage();
              }
            },
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get userChanges => _auth.authStateChanges();

  User? get currentUser  => _auth.currentUser ;
}