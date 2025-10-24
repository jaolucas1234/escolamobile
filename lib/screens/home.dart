import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';
import '../services/storage_service.dart';
import 'atividades.dart';

class Turma {
  final int id;
  final String nome;

  Turma({required this.id, required this.nome});

  factory Turma.fromJson(Map<String, dynamic> json) {
    return Turma(
      id: json['id'] ?? json['id_turma'] ?? 0,
      nome: json['serie'] ?? '', // Use 'serie' como nome da turma
    );
  }
}

class HomeScreen extends StatefulWidget {
  final int professorId;
  final String professorNome;

  const HomeScreen({
    Key? key,
    required this.professorId,
    required this.professorNome,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Turma> _turmas = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showCadastroTurma = false;
  final _turmaNomeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarTurmas();
  }

  Future<void> _carregarTurmas() async {
    try {
      print('Carregando turmas do professor ID: ${widget.professorId}');

      final response = await http.get(
        Uri.parse('http://localhost:3001/turmas/${widget.professorId}'),
      );

      print('Status Code Turmas: ${response.statusCode}');
      print('Response Body Turmas: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _turmas = data.map((json) => Turma.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao carregar turmas: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar turmas: $e');
      setState(() {
        _errorMessage = 'Erro de conexão: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cadastrarTurma() async {
    if (_turmaNomeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe o nome da turma'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('Cadastrando turma para professor ID: ${widget.professorId}');

      final response = await http.post(
        Uri.parse('http://localhost:3001/turmas'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'serie': _turmaNomeController.text,
          'professorId': widget.professorId,
        }),
      );

      print('Status Code Cadastro: ${response.statusCode}');
      print('Response Body Cadastro: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _turmaNomeController.clear();
        setState(() {
          _showCadastroTurma = false;
        });
        await _carregarTurmas();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Turma cadastrada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar turma: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Erro ao cadastrar turma: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro de conexão: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _excluirTurma(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3001/turmas/$id'),
      );

      print('Status Code Exclusão: ${response.statusCode}');
      print('Response Body Exclusão: ${response.body}');

      if (response.statusCode == 204) {
        await _carregarTurmas();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Turma excluída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (response.statusCode == 500) {
        // Trata especificamente o Internal Server Error como turma com atividades
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não é possível apagar uma turma com atividades'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      } else if (response.statusCode == 400 || response.statusCode == 409) {
        // Outros erros de restrição
        final data = json.decode(response.body);
        final errorMessage =
            data['message'] ??
            data['error'] ??
            'Não é possível apagar uma turma com atividades';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        final data = json.decode(response.body);
        final errorMessage =
            data['message'] ?? data['error'] ?? 'Erro ao excluir turma';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('Erro ao excluir turma: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro de conexão: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sair() async {
    await StorageService().logout();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _visualizarTurma(Turma turma) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                AtividadeScreen(turmaId: turma.id, turmaNome: turma.nome),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Turmas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _sair,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com nome do professor
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.professorNome,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${widget.professorId}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Professor',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _sair,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Minhas Turmas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total: ${_turmas.length}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Carregando turmas...'),
                    ],
                  ),
                ),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarTurmas,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_turmas.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nenhuma turma cadastrada',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Clique no botão abaixo para cadastrar sua primeira turma',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _carregarTurmas,
                  child: ListView.builder(
                    itemCount: _turmas.length,
                    itemBuilder: (context, index) {
                      final turma = _turmas[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Text(
                              (index + 1).toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          title: Text(
                            turma.nome, // Mostra apenas o nome
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.visibility,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _visualizarTurma(turma),
                                tooltip: 'Visualizar',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _showDeleteDialog(turma),
                                tooltip: 'Excluir',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: 16),

            if (!_showCadastroTurma)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showCadastroTurma = true;
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Cadastrar Nova Turma'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

            if (_showCadastroTurma) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nova Turma',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Informe o nome da turma para cadastrar',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _turmaNomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome da turma',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                        onSubmitted: (_) => _cadastrarTurma(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _cadastrarTurma,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Salvar Turma'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showCadastroTurma = false;
                                _turmaNomeController.clear();
                              });
                            },
                            child: const Text('Cancelar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Turma turma) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tem certeza que deseja excluir a turma "${turma.nome}"?'),
                const SizedBox(height: 8),
                const Text(
                  '⚠️ Atenção: Turmas com atividades não podem ser excluídas.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _excluirTurma(turma.id);
                },
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _turmaNomeController.dispose();
    super.dispose();
  }
}
