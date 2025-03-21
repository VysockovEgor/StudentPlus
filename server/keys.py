import os
import mammoth

# Укажите путь к папке с вордовскими документами
folder_path = "/home/egor/AndroidStudioProjects/StudentPlus/server/articles"

def convert_docx_to_html(folder):
    for filename in os.listdir(folder):
        if filename.lower().endswith(".docx"):
            docx_path = os.path.join(folder, filename)
            with open(docx_path, "rb") as docx_file:
                result = mammoth.convert_to_html(docx_file)
                html = result.value  # Получаем сгенерированный HTML
                # Выводим сообщения (если есть)
                for message in result.messages:
                    print(f"Сообщение для {filename}: {message}")
            # Формируем имя HTML файла
            html_filename = os.path.splitext(filename)[0] + ".html"
            html_path = os.path.join(folder, html_filename)
            with open(html_path, "w", encoding="utf-8") as html_file:
                html_file.write(html)
            print(f"Конвертирован: {filename} -> {html_filename}")

if __name__ == "__main__":
    convert_docx_to_html(folder_path)
