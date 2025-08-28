import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'addquestionpage.dart';

class CreateQuizPage extends StatefulWidget {
  const CreateQuizPage({super.key});

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _durationController = TextEditingController();
  final _passScoreController = TextEditingController();

  bool _saving = false;
  String? _quizId; // store quizId after save

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final quizRef = await FirebaseFirestore.instance.collection('quizzes').add({
        'title': _titleController.text.trim(),
        'category': _categoryController.text.trim(),
        'duration': int.tryParse(_durationController.text.trim()) ?? 1,
        'passingScore': int.tryParse(_passScoreController.text.trim()) ?? 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _quizId = quizRef.id;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quiz created successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating quiz: $e")),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quiz'),
        backgroundColor: const Color(0xFF5B4FFF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Quiz Title"),
                validator: (v) => v == null || v.isEmpty ? "Enter title" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: "Category"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: "Duration (minutes)"),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? "Enter duration" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passScoreController,
                decoration: const InputDecoration(labelText: "Passing Score (%)"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _saveQuiz,
                    icon: _saving
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Icon(Icons.save),
                    label: const Text('Save Quiz'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_quizId != null)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddQuestionPage(quizId: _quizId!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add Questions"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
