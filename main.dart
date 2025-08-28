import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/start_page.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/student_dashboard.dart';
import 'screens/quiz_list_screen.dart';
import 'screens/createquizpage.dart';
import 'screens/addquestionpage.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();


    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDc5j5qDh_lfhjjLE-mJVUREQyVZXWkShk",
        // from google-services.json
        appId: "1:844715431752:android:d774e8605b69b887b5457d",
        messagingSenderId: "844715431752",
        projectId: "online-quiz-app-af545",
      ),
    );


    runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Online Quiz System',
      theme: ThemeData(
        primaryColor: const Color(0xFF5B4FFF),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF5B4FFF),
          secondary: const Color(0xFF5B4FFF),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5B4FFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ),
      home: const StartPage(),
      routes: {
        '/login': (context) => const LoginFormScreen(),
        '/register': (context) => const RegisterScreen(),
        '/adminDashboard': (context) => const AdminDashboard(adminId: "CURRENT_ADMIN_UID"),
        '/studentDashboard': (context) => const StudentDashboard(),
        '/quizList': (context) => const QuizListScreen(),
        '/createquiz': (context) => const CreateQuizPage(),
        '/addquestion': (context) => const AddQuestionPage(quizId: "PLACEHOLDER_QUIZ_ID"),

      },
    );
  }
}
