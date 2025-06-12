import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? userName;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('profile')
          .doc(widget.userId)
          .get();
      if (userSnapshot.exists) {
        setState(() {
          userName = userSnapshot['name'];
          userEmail = userSnapshot['email'];
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  void handleResetPassword() {
    // Tambahkan logika reset password (misalnya Firebase Auth)
    print("Reset Password Triggered");
  }

  void handleLogout() {
    // Tambahkan logika logout (misalnya Firebase Auth)
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.blueAccent,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  userName ?? "Nama tidak tersedia",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userEmail ?? "Email tidak tersedia",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.black),
            title: const Text('Reset Password'),
            onTap: handleResetPassword,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.black),
            title: const Text('Logout'),
            onTap: handleLogout,
          ),
        ],
      ),
    );
  }
}
