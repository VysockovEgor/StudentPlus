import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:http/http.dart' as http;

class EditorPage extends StatefulWidget {
  final String fileName;

  const EditorPage({Key? key, required this.fileName}) : super(key: key);

  @override
  _EditorPageState createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  // Контроллер для html_editor_enhanced
  final HtmlEditorController _controller = HtmlEditorController();
  bool _isLoading = true;
  String? _error;
  // Хранит начальное содержимое файла
  String _initialText = "";

  @override
  void initState() {
    super.initState();
    fetchFileContent();
  }

  // Запрашиваем содержимое файла с сервера
  Future<void> fetchFileContent() async {
    final url =
        'http://localhost:5000/file/${Uri.encodeComponent(widget.fileName)}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['content'] as String;
        setState(() {
          _initialText = content;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Ошибка загрузки файла';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка: $e';
        _isLoading = false;
      });
    }
  }

  // Сохранение документа: отправляем обновлённый текст на сервер
  Future<void> saveDocument() async {
    // Получаем HTML-текст из редактора
    final updatedContent = await _controller.getText();
    final url =
        'http://localhost:5000/file/${Uri.encodeComponent(widget.fileName)}';
    try {
      final response = await http.post(Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'content': updatedContent}));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл сохранён')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка сохранения файла')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Получаем высоту экрана для полного заполнения редактора
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        // Кнопка сохранения в AppBar всегда доступна и кликабельна
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveDocument,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Theme(
        // Оборачиваем в Theme с тёмной темой для светлого текста в тулбаре
        data: ThemeData.dark().copyWith(
          // Настраиваем иконки и текст в тулбаре
          iconTheme: const IconThemeData(color: Colors.white),
          textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),
        child: HtmlEditor(
          controller: _controller,
          htmlEditorOptions: HtmlEditorOptions(
            initialText: _initialText,
            // Включаем тёмный режим: фон тёмный, контент — светлый
            darkMode: true,
          ),
          htmlToolbarOptions: const HtmlToolbarOptions(
            // Набор кнопок остаётся прежним
            defaultToolbarButtons: [
              StyleButtons(),
              FontButtons(),
              ColorButtons(),
              ListButtons(),
              ParagraphButtons(),
              InsertButtons(),
              OtherButtons(),
            ],
          ),
          otherOptions: OtherOptions(
            // Высота редактора равна высоте экрана
            height: screenHeight,
          ),
        ),
      ),
    );
  }
}
