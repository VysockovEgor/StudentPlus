import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from src.create_articles.create_articles import generate_article
from src.vector_analyst.vector_analyst import vector_analyst

app = Flask(__name__)
CORS(app)

FILES_DIRECTORY = "articles"


# Эндпоинт для получения списка HTML-файлов
@app.route('/files', methods=['GET'])
def get_files():
    if not os.path.exists(FILES_DIRECTORY):
        os.makedirs(FILES_DIRECTORY)
    html_files = [f for f in os.listdir(FILES_DIRECTORY) if f.endswith('.html')]
    return jsonify(html_files)


# Эндпоинт для получения содержимого HTML-файла
@app.route('/file/<filename>', methods=['GET'])
def get_file_content(filename):
    file_path = os.path.join(FILES_DIRECTORY, filename)
    if not os.path.exists(file_path):
        return jsonify({'error': 'Файл не найден'}), 404
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        return jsonify({'content': content})
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Эндпоинт для сохранения содержимого HTML-файла
@app.route('/file/<filename>', methods=['POST'])
def save_file_content(filename):
    file_path = os.path.join(FILES_DIRECTORY, filename)
    data = request.get_json()
    content = data.get('content', '')
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return jsonify({'message': 'Файл успешно сохранён'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Эндпоинт для удаления HTML-файла
@app.route('/file/<filename>', methods=['DELETE'])
def delete_file(filename):
    file_path = os.path.join(FILES_DIRECTORY, filename)
    if not os.path.exists(file_path):
        return jsonify({'error': 'Файл не найден'}), 404
    try:
        os.remove(file_path)
        return jsonify({'message': 'Файл успешно удалён'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Эндпоинт для генерации статьи. Статья сохраняется как HTML-файл
@app.route('/article', methods=['POST'])
def create_article():
    data = request.get_json()
    title = data.get('title')
    instructions = data.get('instructions')

    article_text = generate_article(title, instructions)
    # Имя файла определяется на основе заголовка статьи с расширением .html
    file_name = f"{title}.html"
    file_path = os.path.join(FILES_DIRECTORY, file_name)
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(article_text)
        return jsonify({'message': 'Статья получена'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Эндпоинт для получения точек (результат работы vector_analyst)
@app.route('/points', methods=['GET'])
def get_points():
    return jsonify(vector_analyst())


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
