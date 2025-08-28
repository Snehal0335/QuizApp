import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'createquizpage.dart';
import 'addquestionpage.dart';

class AdminDashboard extends StatefulWidget {
  final String adminId; // Admin UID

  const AdminDashboard({super.key, required this.adminId});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String selectedMenu = 'Dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedMenu),
        backgroundColor: const Color(0xFF5B4FFF),
      ),
      drawer: _buildDrawer(),
      body: _getBodyContent(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF5B4FFF)),
              child: Row(
                children: const [
                  Icon(Icons.menu_book, color: Colors.white, size: 36),
                  SizedBox(width: 12),
                  Text(
                    'QuizMaster',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _drawerTile('Dashboard', Icons.dashboard),
            _drawerTile('Create Quiz', Icons.add, navigateToCreate: true),
            _drawerTile('Manage Quizzes', Icons.quiz),
            _drawerTile('Reports', Icons.bar_chart),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Administrator',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(String title, IconData icon,
      {bool navigateToCreate = false}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selectedMenu == title,
      onTap: () {
        Navigator.pop(context);
        if (navigateToCreate) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const CreateQuizPage()));
        } else {
          setState(() => selectedMenu = title);
        }
      },
    );
  }

  Widget _getBodyContent() {
    switch (selectedMenu) {
      case 'Dashboard':
        return _dashboardContent();
      case 'Manage Quizzes':
        return _manageQuizzesContent();
      case 'Reports':
        return _reportsContent();
      default:
        return const Center(child: Text('Welcome'));
    }
  }

  Widget _dashboardContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Admin Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _statCard('Total Quizzes', '0', Colors.blue),
                _statCard('Total Students', '0', Colors.orange),
                _statCard('Total Attempts', '0', Colors.green),
                _statCard('Pending Quizzes', '0', Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, color: color)),
        ],
      ),
    );
  }

  /// Manage Quizzes
  Widget _manageQuizzesContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No quizzes created yet."));
        }

        final quizzes = snapshot.data!.docs;

        return ListView.builder(
          itemCount: quizzes.length,
          itemBuilder: (context, index) {
            final quiz = quizzes[index];
            final quizData = quiz.data()! as Map<String, dynamic>;

            final title = quizData['title'] ?? "No Title";
            final description = quizData['description'] ?? "";
            final questions = List<Map<String, dynamic>>.from(
                quizData['questions'] ?? []);

            return Card(
              margin: const EdgeInsets.all(8),
              child: ExpansionTile(
                title: Text(title),
                subtitle: Text(description),
                children: [
                  ...questions
                      .asMap()
                      .entries
                      .map((entry) {
                    final qIndex = entry.key;
                    final question = entry.value;
                    return ListTile(
                      title: Text(question['question'] ?? ""),
                      subtitle: Text("Answer: ${question['answer'] ?? ""}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showEditQuestionDialog(
                                    quiz.id, qIndex, question),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final updatedQuestions = List<
                                  Map<String, dynamic>>.from(questions);
                              updatedQuestions.removeAt(qIndex);
                              await FirebaseFirestore.instance
                                  .collection('quizzes')
                                  .doc(quiz.id)
                                  .update({'questions': updatedQuestions});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Question deleted")),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 8),
                  // Add Question
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showAddQuestionDialog(quiz.id, questions),
                      icon: const Icon(Icons.add),
                      label: const Text("Add Question"),
                    ),
                  ),
                  // Edit Quiz Info
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showEditQuizDialog(
                              context, quiz.id, title, description),
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit Quiz Info"),
                    ),
                  ),
                  // Delete Quiz
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('quizzes')
                            .doc(quiz.id)
                            .delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Quiz deleted")),
                        );
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text("Delete Quiz"),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Edit/Add Question Dialogs ---

  void _showEditQuestionDialog(String quizId, int questionIndex,
      Map<String, dynamic> question) {
    final _questionController = TextEditingController(
        text: question['question']);
    final _answerController = TextEditingController(text: question['answer']);

    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text("Edit Question"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _questionController,
                    decoration: const InputDecoration(labelText: "Question")),
                TextField(controller: _answerController,
                    decoration: const InputDecoration(labelText: "Answer")),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  final doc = await FirebaseFirestore.instance.collection(
                      'quizzes').doc(quizId).get();
                  final quizData = doc.data()! as Map<String, dynamic>;
                  final questions = List<Map<String, dynamic>>.from(
                      quizData['questions'] ?? []);

                  questions[questionIndex] = {
                    'question': _questionController.text.trim(),
                    'answer': _answerController.text.trim(),
                  };

                  await FirebaseFirestore.instance.collection('quizzes').doc(
                      quizId).update({'questions': questions});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Question updated successfully")),
                  );
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  void _showAddQuestionDialog(String quizId,
      List<Map<String, dynamic>> currentQuestions) {
    // Instead of showing a dialog, navigate to AddQuestionPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddQuestionPage(quizId: quizId),
      ),
    );
  }


  void _showEditQuizDialog(BuildContext context, String quizId,
      String currentTitle, String currentDesc) {
    final _titleController = TextEditingController(text: currentTitle);
    final _descController = TextEditingController(text: currentDesc);

    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text("Edit Quiz Info"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _titleController,
                    decoration: const InputDecoration(labelText: "Quiz Title")),
                TextField(controller: _descController,
                    decoration: const InputDecoration(
                        labelText: "Description")),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('quizzes').doc(
                      quizId).update({
                    'title': _titleController.text.trim(),
                    'description': _descController.text.trim(),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Quiz updated successfully")),
                  );
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }
  Widget _reportsContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No reports available"));
        }

        final reports = snapshot.data!.docs;

        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final data = reports[index].data() as Map<String, dynamic>;

            final studentName = data['studentName'] ?? "Unknown Student";
            final quizTitle = data['quizTitle'] ?? "Unknown Test";
            final score = data['scorePercent'] ?? 0;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF5B4FFF)),
                title: Text(studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Test: $quizTitle"),
                trailing: Text(
                  "$score%",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: score >= 50 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

}