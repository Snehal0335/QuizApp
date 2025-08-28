import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Student Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${currentUser?.email ?? "Student"}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Take Quiz Card
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.quiz, size: 40, color: Colors.blue),
                title:
                const Text('Take a Quiz', style: TextStyle(fontSize: 18)),
                subtitle:
                const Text('View available quizzes and attempt them'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.pushNamed(context, '/quizList');
                },
              ),
            ),
            const SizedBox(height: 20),

          ],
        ),
      ),
    );
  }


}
