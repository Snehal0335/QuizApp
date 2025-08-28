import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddQuestionPage extends StatefulWidget {
  final String quizId;
  final bool isEditing;
  final int? questionIndex; // index of question in array when editing

  const AddQuestionPage({
    super.key,
    required this.quizId,
    this.isEditing = false,
    this.questionIndex,
  });

  @override
  State<AddQuestionPage> createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  final List<TextEditingController> _optionControllers =
  List.generate(4, (_) => TextEditingController());

  String _selectedType = "MCQ";
  bool _saving = false;
  List _questionsList = [];

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    final quizRef = FirebaseFirestore.instance.collection('quizzes').doc(widget.quizId);
    final quizSnap = await quizRef.get();

    if (quizSnap.exists) {
      _questionsList = quizSnap.data()?['questions'] ?? [];

      // If editing, load data from specific question index
      if (widget.isEditing && widget.questionIndex != null) {
        final question = Map<String, dynamic>.from(_questionsList[widget.questionIndex!]);
        _questionController.text = question['question'] ?? "";
        _answerController.text = question['answer'] ?? "";
        _selectedType = question['type'] ?? "MCQ";

        if (_selectedType == "MCQ" && question['options'] != null) {
          final options = List<String>.from(question['options']);
          for (int i = 0; i < _optionControllers.length; i++) {
            if (i < options.length) _optionControllers[i].text = options[i];
          }
        }

        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    for (var c in _optionControllers) c.dispose();
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      Map<String, dynamic> questionData = {
        "question": _questionController.text.trim(),
        "type": _selectedType,
        "answer": _answerController.text.trim(),
      };

      if (_selectedType == "MCQ") {
        final options = _optionControllers
            .map((c) => c.text.trim())
            .where((o) => o.isNotEmpty)
            .toList();

        if (options.length < 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please enter at least 2 options")),
          );
          setState(() => _saving = false);
          return;
        }

        questionData['options'] = options;
      } else if (_selectedType == "True/False") {
        questionData['options'] = ["True", "False"];
      }

      final quizRef = FirebaseFirestore.instance.collection('quizzes').doc(widget.quizId);

      if (widget.isEditing && widget.questionIndex != null) {
        // Update existing question
        _questionsList[widget.questionIndex!] = questionData;
      } else {
        // Add new question
        _questionsList.add(questionData);
      }

      await quizRef.update({'questions': _questionsList});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.isEditing
                ? "✅ Question updated successfully"
                : "✅ Question added successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving question: $e")),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? "Edit Question" : "Add Question"),
        backgroundColor: const Color(0xFF5B4FFF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: "Question",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                val == null || val.isEmpty ? "Enter question" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: "Question Type",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "MCQ", child: Text("MCQ")),
                  DropdownMenuItem(value: "True/False", child: Text("True/False")),
                ],
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 16),

              // MCQ options
              if (_selectedType == "MCQ") ...[
                for (int i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: TextFormField(
                      controller: _optionControllers[i],
                      decoration: InputDecoration(
                        labelText: "Option ${i + 1}",
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                TextFormField(
                  controller: _answerController,
                  decoration: const InputDecoration(
                    labelText: "Correct Answer",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                  val == null || val.isEmpty ? "Enter correct answer" : null,
                ),
              ],

              // True/False
              if (_selectedType == "True/False") ...[
                const Text("Correct Answer:", style: TextStyle(fontWeight: FontWeight.w600)),
                RadioListTile<String>(
                  title: const Text("True"),
                  value: "True",
                  groupValue: _answerController.text,
                  onChanged: (val) => setState(() => _answerController.text = val!),
                ),
                RadioListTile<String>(
                  title: const Text("False"),
                  value: "False",
                  groupValue: _answerController.text,
                  onChanged: (val) => setState(() => _answerController.text = val!),
                ),
              ],


              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saving ? null : _saveQuestion,
                icon: _saving
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Icon(Icons.save),
                label: Text(widget.isEditing ? "Update Question" : "Save Question"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
