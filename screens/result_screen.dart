import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic>? quizData;
  final List<Map<String, dynamic>>? questions;
  final Map<int, dynamic>? userAnswers;
  final int? scorePercent;
  final bool autoSubmitted;
  final String studentId;
  final String studentName;

  const ResultScreen({
    super.key,
    this.quizData,
    this.questions,
    this.userAnswers,
    this.scorePercent,
    this.autoSubmitted = false,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    _saveReport();
  }

  Future<void> _saveReport() async {
    try {
      final reportData = {
        'studentId': widget.studentId,
        'studentName': widget.studentName,
        'quizTitle': widget.quizData?['title'] ?? "Unknown Test",
        'scorePercent': widget.scorePercent ?? 0,
        'createdAt': DateTime.now(),
      };

      await FirebaseFirestore.instance.collection('reports').add(reportData);
      print("Report saved ✅");
    } catch (e) {
      print("Error saving report: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quizData ?? {};
    final qs = widget.questions ?? [];
    final ua = widget.userAnswers ?? {};
    final score = widget.scorePercent ?? 0;
    final wasAuto = widget.autoSubmitted;
    final passMark = (quiz['passingScore'] ?? 0) as int;
    final passed = score >= passMark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        backgroundColor: const Color(0xFF5B4FFF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quiz['title'] ?? 'Quiz',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text('Score: $score%'),
                  backgroundColor: passed ? Colors.green : Colors.red,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('Pass Mark: $passMark%'),
                  backgroundColor: const Color(0xFF5B4FFF),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 8),
                if (wasAuto) const Chip(label: Text('Auto-Submitted')),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Review',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: qs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final q = qs[index];
                  final type = (q['type'] ?? '').toString();
                  final correctAns = (q['answer'] ?? '').toString();
                  final userAns = (ua[index] ?? '').toString();
                  final isCorrect = _isCorrect(type, correctAns, userAns);

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(q['question'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text('Your answer: $userAns'),
                          Text('Correct answer: $correctAns'),
                        ],
                      ),
                      trailing: Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.list),
                label: const Text('Back to Quiz List'),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isCorrect(String type, String correctAns, String userAns) {
    final t = type.toLowerCase();
    if (t == 'mcq' || t == 'true/false' || t == 'truefalse') {
      return userAns == correctAns;
    } else {
      return userAns.trim().toLowerCase() == correctAns.trim().toLowerCase();
    }
  }
}
