import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_attempt_screen.dart';

class QuizListScreen extends StatelessWidget {
  const QuizListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Quizzes'),
        backgroundColor: const Color(0xFF5B4FFF),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('quizzes').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No quizzes available.'));
          }

          final quizzes = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quizDoc = quizzes[index];
              final quiz = quizDoc.data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    quiz['title'] ?? 'Untitled Quiz',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Category: ${quiz['category'] ?? '-'} · Duration: ${quiz['duration'] ?? 0} min · Pass: ${quiz['passingScore'] ?? 0}%',
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizAttemptScreen(
                            quizId: quizDoc.id,
                          ),
                        ),
                      );
                    },
                    child: const Text('Start'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
