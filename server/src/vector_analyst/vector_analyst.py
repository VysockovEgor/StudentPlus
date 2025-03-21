import os
import random
import numpy as np
from scipy.optimize import least_squares
from sklearn.metrics.pairwise import cosine_distances
from src.vector_analyst.vector_transforming import *

import os

# Получаем путь до корня проекта, а затем переходим к папке 'articles'
folder_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'articles')
def trilaterate_new_point(points, distances):
    """
    Вычисляет координаты новой точки в 3D на основе расстояний до известных точек.
    """
    if len(points) == 1:
        return np.array([distances[0], 0.0, 0.0])
    elif len(points) == 2:
        d = np.linalg.norm(points[1] - points[0])
        x = (distances[0] ** 2 - distances[1] ** 2 + d ** 2) / (2 * d)
        y = np.sqrt(max(distances[0] ** 2 - x ** 2, 0))
        return np.array([x, y, 0.0])
    else:
        def residuals(x, pts, dists):
            return np.linalg.norm(pts - x, axis=1) - dists

        initial_guess = np.mean(points, axis=0)
        result = least_squares(residuals, initial_guess, args=(points, distances))
        return result.x


def create_coordinate_map(coordinates, filenames):
    """Создает список словарей с координатами, названием файла и цветом."""
    return [
        {
            "x": float(x),
            "y": float(y),
            "z": float(z),
            "articleTitle": filenames[i],
            "color": "#{:06x}".format(random.randint(0, 0xFFFFFF))
        }
        for i, (x, y, z) in enumerate(coordinates)
    ]


def vector_analyst():
    # Путь к папке с документами


    # Получаем список файлов .docx
    word_files = [f for f in os.listdir(folder_path) if f.endswith(".html")]
    if not word_files:
        return

    # Загружаем и обрабатываем документы
    docs = load_documents(folder_path)


    processed_docs = preprocess_documents(docs, language="russian")
    tfidf_matrix, _ = vectorize_documents(processed_docs)

    # Инициализация системы координат
    coordinates = [np.array([0.0, 0.0, 0.0])]  # Первый документ в начале координат

    # Последовательное добавление документов
    for i in range(1, len(processed_docs)):
        dists = cosine_distances(tfidf_matrix[i:i + 1], tfidf_matrix[:i])[0]
        new_point = trilaterate_new_point(np.array(coordinates), dists)
        coordinates.append(new_point)


    # Создание итоговой матрицы координат с названиями и цветами
    coordinate_matrix = create_coordinate_map(coordinates, word_files)

    return coordinate_matrix

