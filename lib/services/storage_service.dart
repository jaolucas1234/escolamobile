import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _professorIdKey = 'professor_id';
  static const String _professorNameKey = 'professor_name';

  // Salvar dados do login
  Future<void> saveLoginData(int professorId, String professorName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_professorIdKey, professorId);
    await prefs.setString(_professorNameKey, professorName);
  }

  // Obter ID do professor
  Future<int?> getProfessorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_professorIdKey);
  }

  // Obter nome do professor
  Future<String?> getProfessorName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_professorNameKey);
  }

  // Verificar se usuário está logado
  Future<bool> isLoggedIn() async {
    final professorId = await getProfessorId();
    return professorId != null;
  }

  // Logout - limpar dados
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_professorIdKey);
    await prefs.remove(_professorNameKey);
  }
}
