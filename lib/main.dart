import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isLoggedIn = await StorageService().isLoggedIn();

  if (isLoggedIn) {
    final professorId = await StorageService().getProfessorId();
    final professorName = await StorageService().getProfessorName();

    runApp(
      MyApp(
        initialScreen: HomeScreen(
          professorId: professorId!,
          professorNome: professorName ?? 'Professor',
        ),
      ),
    );
  } else {
    runApp(MyApp(initialScreen: const LoginScreen()));
  }
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({Key? key, required this.initialScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Turmas',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: initialScreen,
      debugShowCheckedModeBanner: false,
    );
  }
}
