import re
from nltk.corpus import stopwords
from nltk.stem import SnowballStemmer

import os
import glob
from bs4 import BeautifulSoup


def load_documents(folder_path, file_extension="*.html"):
    """
    Сканирует указанную папку и возвращает список строк – содержимое всех найденных HTML-документов.

    :param folder_path: Путь к папке с документами.
    :param file_extension: Шаблон для поиска файлов (по умолчанию "*.html").
    :return: Список текстов документов.
    """
    file_paths = glob.glob(os.path.join(folder_path, file_extension))
    documents = []

    for file_path in file_paths:
        try:
            with open(file_path, "r", encoding="utf-8") as file:
                soup = BeautifulSoup(file, "html.parser")
                text = soup.get_text(separator="\n").strip().replace("\n", "")
                documents.append(text)
        except Exception as e:
            print(f"Ошибка при чтении файла {file_path}: {e}")
    print(documents)
    return documents



# Если стоп-слова для русского языка не скачаны, раскомментируйте следующую строку:
# nltk.download("stopwords")

def preprocess_text(text, language="russian"):
    """
    Выполняет предобработку текста:
      - приводит текст к нижнему регистру;
      - удаляет HTML-теги (если есть);
      - оставляет только русские буквы (включая ё) и пробелы;
      - выполняет токенизацию (разбивку по пробелам);
      - удаляет стоп-слова;
      - выполняет стемминг.

    :param text: Исходный текст.
    :param language: Язык для стоп-слов и стемминга (по умолчанию "russian").
    :return: Предобработанный текст в виде строки.
    """
    # Приводим текст к нижнему регистру
    text = text.lower()
    # Удаляем HTML-теги
    text = re.sub(r'<[^>]+>', ' ', text)
    # Оставляем только русские буквы (а-я, ё) и пробелы
    text = re.sub(r'[^а-яё\s]', ' ', text)
    # Токенизируем текст
    tokens = text.split()
    # Удаляем стоп-слова
    stop_words = set(stopwords.words(language))
    tokens = [token for token in tokens if token not in stop_words]
    # Стемминг с использованием SnowballStemmer для русского языка
    stemmer = SnowballStemmer(language)
    tokens = [stemmer.stem(token) for token in tokens]
    # Объединяем токены обратно в строку
    processed_text = " ".join(tokens)
    return processed_text

def preprocess_documents(documents, language="russian"):
    """
    Применяет предобработку ко всем документам из списка.

    :param documents: Список исходных текстов документов.
    :param language: Язык для предобработки (по умолчанию "russian").
    :return: Список предобработанных текстов.
    """
    return [preprocess_text(doc, language) for doc in documents]


from sklearn.feature_extraction.text import TfidfVectorizer


def vectorize_documents(documents, max_features=5000):
    """
    Преобразует список документов в TF-IDF матрицу.

    :param documents: Список предобработанных текстов документов.
    :param max_features: Максимальное число признаков (словарный запас), по умолчанию 5000.
    :return: Кортеж из TF-IDF матрицы (sparse matrix) и списка имен признаков.
    """
    vectorizer = TfidfVectorizer(max_features=max_features)
    tfidf_matrix = vectorizer.fit_transform(documents)
    feature_names = vectorizer.get_feature_names_out()
    return tfidf_matrix, feature_names
