import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'result_screen.dart';

class QuizAttemptScreen extends StatefulWidget {
  final String quizId;
  const QuizAttemptScreen({super.key, required this.quizId});

  @override
  State<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends State<QuizAttemptScreen> {
  Map<String, dynamic>? quiz;
  List<Map<String, dynamic>> questions = [];

  int currentIndex = 0;
  final Map<int, String> userAnswers = {};
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _loading = true;

  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _fetchQuizData();
  }

  Future<void> _fetchQuizData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz not found')),
          );
          Navigator.pop(context);
        }
        return;
      }
      quiz = doc.data();

      final qsnap = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .collection('questions')
          .get();

      questions = qsnap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return _normalizeQuestion(data);
      }).toList();

      if (questions.isEmpty) {
        final embedded = (quiz?['questions'] as List?) ?? [];
        questions = embedded
            .map((e) => _normalizeQuestion(Map<String, dynamic>.from(e)))
            .toList();
      }

      if (questions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No questions in this quiz yet')),
          );
          Navigator.pop(context);
        }
        return;
      }

      final totalMinutes = (quiz?['duration'] is int)
          ? quiz!['duration'] as int
          : int.tryParse('${quiz?['duration'] ?? 1}') ?? 1;
      _remainingSeconds = totalMinutes * 60;

      setState(() => _loading = false);
      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading quiz: $e")),
        );
        Navigator.pop(context);
      }
    }
  }

  Map<String, dynamic> _normalizeQuestion(Map<String, dynamic> q) {
    final out = <String, dynamic>{...q};
    String type = (q['type'] ?? '').toString().trim();
    final options = (q['options'] as List?)?.map((e) => '$e').toList() ?? [];

    if (type.isEmpty) {
      if (options.isNotEmpty) {
        final lower = options.map((e) => e.toLowerCase()).toList();
        if (lower.length == 2 &&
            lower.contains('true') &&
            lower.contains('false')) {
          type = 'True/False';
        } else {
          type = 'MCQ';
        }
      } else {
        type = 'Short Answer';
      }
    }

    String answer = (q['answer'] ?? '').toString();
    if (answer.isEmpty && q.containsKey('correctOption')) {
      final co = q['correctOption'];
      if (co is int) {
        if (co >= 0 && co < options.length) answer = options[co];
      } else if (co is String) {
        if (options.contains(co)) {
          answer = co;
        } else if (co.toLowerCase().startsWith('option')) {
          final idx = int.tryParse(co.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          if (idx > 0 && idx <= options.length) answer = options[idx - 1];
        } else {
          answer = co;
        }
      }
    }

    if (type.toLowerCase().contains('true') && options.isEmpty) {
      out['options'] = ['True', 'False'];
    }

    out['type'] = type;
    out['answer'] = answer;
    if (options.isNotEmpty) out['options'] = options;

    return out;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remainingSeconds <= 0) {
        t.cancel();
        _submit(autoSubmit: true);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _selectAnswer(String value) {
    setState(() => userAnswers[currentIndex] = value);
  }

  void _next() {
    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
    }
  }

  void _prev() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
    }
  }

  Future<void> _submit({bool autoSubmit = false}) async {
    _timer?.cancel();

    int correct = 0;
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final type = (q['type'] ?? '').toString().toLowerCase();
      final correctAns = (q['answer'] ?? '').toString().trim();
      final userAns = (userAnswers[i] ?? '').toString().trim();

      bool isRight;
      if (type == 'mcq' || type.contains('true')) {
        isRight = userAns == correctAns;
      } else {
        isRight = userAns.toLowerCase() == correctAns.toLowerCase();
      }
      if (isRight) correct++;
    }

    final scorePercent = ((correct / questions.length) * 100).round();

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'anonymous';
      final studentName = user?.email ?? 'Unknown';

      // ✅ FIX: Save inside quizzes/{quizId}/attempts
      await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .collection('attempts')
          .add({
        'studentId': uid,
        'studentName': studentName,
        'answers': userAnswers,
        'scorePercent': scorePercent,
        'attemptedAt': FieldValue.serverTimestamp(),
        'autoSubmitted': autoSubmit,
        'total': questions.length,
      });
    } catch (e) {
      debugPrint("Error saving attempt: $e");
    }

    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          quizData: quiz!,
          questions: questions,
          userAnswers: userAnswers,
          scorePercent: scorePercent,
          autoSubmitted: autoSubmit,
          studentId: user?.uid ?? 'anonymous',
          studentName: user?.email ?? 'Unknown',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final q = questions[currentIndex];
    final type = (q['type'] ?? '').toString().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(quiz?['title'] ?? 'Quiz'),
        backgroundColor: const Color(0xFF5B4FFF),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Chip(
              label: Text(
                _formatTime(_remainingSeconds),
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF5B4FFF),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Question ${currentIndex + 1} of ${questions.length}",
                style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Text(q['question'] ?? "", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),

            if (type == 'mcq') ..._buildMcq(q)
            else if (type.contains('true')) ..._buildTrueFalse(q)
            else ..._buildShortAnswer(q),

            const Spacer(),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: _prev, child: const Text("Previous"))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton(
                        onPressed: _next, child: const Text("Next"))),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text("Submit"),
                onPressed: () => _submit(autoSubmit: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMcq(Map<String, dynamic> q) {
    final opts = (q['options'] as List?)?.map((e) => '$e').toList() ?? [];
    final selected = userAnswers[currentIndex] ?? '';
    return opts.map((opt) {
      return RadioListTile<String>(
        value: opt,
        groupValue: selected,
        onChanged: (v) => _selectAnswer(v ?? ''),
        title: Text(opt),
        activeColor: const Color(0xFF5B4FFF),
      );
    }).toList();
  }

  List<Widget> _buildTrueFalse(Map<String, dynamic> q) {
    final opts =
        (q['options'] as List?)?.map((e) => '$e').toList() ?? ['True', 'False'];
    final selected = userAnswers[currentIndex] ?? '';
    return opts.map((opt) {
      return RadioListTile<String>(
        value: opt,
        groupValue: selected,
        onChanged: (v) => _selectAnswer(v ?? ''),
        title: Text(opt),
        activeColor: const Color(0xFF5B4FFF),
      );
    }).toList();
  }

  List<Widget> _buildShortAnswer(Map<String, dynamic> q) {
    if (!_controllers.containsKey(currentIndex)) {
      _controllers[currentIndex] =
          TextEditingController(text: userAnswers[currentIndex] ?? '');
    }
    final controller = _controllers[currentIndex]!;
    return [
      TextField(
        controller: controller,
        decoration: const InputDecoration(
            labelText: "Your Answer", border: OutlineInputBorder()),
        onChanged: (v) => _selectAnswer(v),
      ),
    ];
  }
}
