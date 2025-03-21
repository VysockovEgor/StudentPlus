import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../db.dart';
import 'editor.dart';

// Страница со списком файлов
class SlideUpPage extends StatefulWidget {
  const SlideUpPage({Key? key}) : super(key: key);

  @override
  _SlideUpPageState createState() => _SlideUpPageState();
}

class _SlideUpPageState extends State<SlideUpPage> {
  List<String> wordFiles = [];

  @override
  void initState() {
    super.initState();
    fetchFiles();
  }

  Future<void> fetchFiles() async {
    final response = await http.get(Uri.parse('http://localhost:5000/files'));
    if (response.statusCode == 200) {
      setState(() {
        wordFiles = List<String>.from(json.decode(response.body));
      });
    } else {
      // Обработка ошибки запроса
      throw Exception('Ошибка при получении списка файлов');
    }
  }

  // Метод для удаления файла
  Future<void> _deleteFile(String fileName) async {
    final url =
        'http://localhost:5000/file/${Uri.encodeComponent(fileName)}';
    try {
      final response = await http.delete(Uri.parse(url));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Файл "$fileName" удалён')),
        );
        fetchFiles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления файла "$fileName"')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  // Метод для показа диалога выбора действия
  void _showCreateOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите действие'),
        content: const Text('1. Создать пустой файл\n2. Создать статью'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _createEmptyFile(context);
            },
            child: const Text('Создать пустой файл'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _createArticle(context);
            },
            child: const Text('Создать статью'),
          ),
        ],
      ),
    );
  }

  // Диалог для создания пустого файла: ввод названия и переход к редактору
  void _createEmptyFile(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Введите название файла'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Название файла'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // закрываем диалог ввода
              final fileName = controller.text.trim();
              if (fileName.isNotEmpty) {
                // Переходим на страницу редактора с новым файлом
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditorPage(fileName: fileName),
                  ),
                );
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }


  void _createArticle(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController instructionsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать статью'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Название страницы',
              ),
            ),
            TextField(
              controller: instructionsController,
              decoration: const InputDecoration(
                labelText: 'Инструкции по созданию',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final title = titleController.text.trim();
              final instructions = instructionsController.text.trim();
              if (title.isNotEmpty && instructions.isNotEmpty) {
                Navigator.pop(context);
                _submitArticle(title, instructions);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Заполните оба поля')),
                );
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitArticle(String title, String instructions) async {
    // Показываем диалог загрузки (анимация)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    final url = 'http://localhost:5000/article';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': title,
          'instructions': instructions,
        }),
      );

      // Закрываем диалог загрузки
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Все успешно')),
        );
        // Обновляем граф (например, перезагружаем список точек)
        await DB.fetchPoints();
        // Ждем пару секунд для гарантии сохранения файла на сервере
        await Future.delayed(const Duration(seconds: 1));
        // Переходим в редактор с файлом, название которого ввёл пользователь
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditorPage(fileName: title),
          ),
        );
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка отправки статьи')),
        );
      }
    } catch (e) {
      // В случае ошибки закрываем диалог загрузки и показываем сообщение
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black26,
      // Размещаем две плавающих кнопки (плюс и стрелка)
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "addButton",
            onPressed: () => _showCreateOptions(context),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "backButton",
            onPressed: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: wordFiles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: wordFiles.length,
        itemBuilder: (context, index) {
          final fileName = wordFiles[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: WordFileCard(
              fileName: fileName,
              onDelete: _deleteFile,
            ),
          );
        },
      ),
    );
  }
}

class WordFileCard extends StatelessWidget {
  final String fileName;
  final Function(String) onDelete;

  const WordFileCard({
    Key? key,
    required this.fileName,
    required this.onDelete,
  }) : super(key: key);

  // Показываем диалог подтверждения удаления
  void _confirmDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердите удаление'),
        content: Text('Вы действительно хотите удалить файл "$fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete(fileName);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(
          Icons.article,
          color: Colors.blue,
          size: 40,
        ),
        title: Text(
          fileName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        // Используем Row для размещения двух иконок: навигация и удаление
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onPressed: () {
                // Переходим на страницу редактора
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditorPage(fileName: fileName),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDeletion(context),
            ),
          ],
        ),
      ),
    );
  }
}
