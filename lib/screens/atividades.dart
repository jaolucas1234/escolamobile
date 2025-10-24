import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Atividade {
  final int id;
  final String descricao;

  Atividade({required this.id, required this.descricao});

  factory Atividade.fromJson(Map<String, dynamic> json) {
    return Atividade(
      id: json['id'] ?? json['id_atividade'] ?? 0,
      descricao: json['descricao'] ?? '',
    );
  }
}

class AtividadeScreen extends StatefulWidget {
  final int turmaId;
  final String turmaNome;

  const AtividadeScreen({
    Key? key,
    required this.turmaId,
    required this.turmaNome,
  }) : super(key: key);

  @override
  _AtividadeScreenState createState() => _AtividadeScreenState();
}

class _AtividadeScreenState extends State<AtividadeScreen> {
  List<Atividade> _atividades = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showCadastroAtividade = false;
  final _descricaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarAtividades();
  }

  Future<void> _carregarAtividades() async {
    try {
      print('Carregando atividades da turma ID: ${widget.turmaId}');

      final response = await http.get(
        Uri.parse('http://localhost:3001/atividades/${widget.turmaId}'),
      );

      print('Status Code Atividades: ${response.statusCode}');
      print('Response Body Atividades: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _atividades = data.map((json) => Atividade.fromJson(json)).toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        // Se for 404 (não encontrado), trata como lista vazia
        setState(() {
          _atividades = [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao carregar atividades: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar atividades: $e');
      setState(() {
        _errorMessage = 'Erro de conexão: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cadastrarAtividade() async {
    if (_descricaoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe a descrição da atividade'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('Cadastrando atividade para turma ID: ${widget.turmaId}');

      final response = await http.post(
        Uri.parse('http://localhost:3001/atividades'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'descricao': _descricaoController.text,
          'turmaId': widget.turmaId,
        }),
      );

      print('Status Code Cadastro Atividade: ${response.statusCode}');
      print('Response Body Cadastro Atividade: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _descricaoController.clear();
        setState(() {
          _showCadastroAtividade = false;
        });
        await _carregarAtividades();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atividade cadastrada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao cadastrar atividade: ${response.statusCode}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Erro ao cadastrar atividade: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro de conexão: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.turmaNome),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com nome da turma
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
                          widget.turmaNome,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Cadastrar atividade',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Lista de atividades
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Carregando atividades...'),
                          ],
                        ),
                      )
                      : _errorMessage != null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _carregarAtividades,
                              child: const Text('Tentar Novamente'),
                            ),
                          ],
                        ),
                      )
                      : _atividades.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Nenhuma atividade cadastrada',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Clique no botão abaixo para cadastrar a primeira atividade',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: _atividades.length,
                        itemBuilder: (context, index) {
                          final atividade = _atividades[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green[100],
                                child: Text(
                                  (index + 1).toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              title: Text(
                                atividade.descricao,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),

            const SizedBox(height: 16),

            // Botão para cadastrar nova atividade
            if (!_showCadastroAtividade)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showCadastroAtividade = true;
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Cadastrar Nova Atividade'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

            // Formulário de cadastro de atividade
            if (_showCadastroAtividade) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nova atividade',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Informe a descrição da atividade para a turma selecionada.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descricaoController,
                        decoration: const InputDecoration(
                          labelText: 'Descrição da atividade',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.assignment),
                        ),
                        maxLines: 3,
                        onSubmitted: (_) => _cadastrarAtividade(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _cadastrarAtividade,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Salvar'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showCadastroAtividade = false;
                                _descricaoController.clear();
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

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }
}
