import time
import numpy as np
import psycopg2
from scipy.interpolate import interp1d

# Подключение к базе данных PostgreSQL
conn = psycopg2.connect(
    dbname="mydb",
    user="user",
    password="5309",
    host="localhost",
    port="5432"
)
cursor = conn.cursor()

# Создание таблицы для хранения результатов
cursor.execute("""
    CREATE TABLE IF NOT EXISTS interpolation_results (
        id SERIAL PRIMARY KEY,
        x_value FLOAT NOT NULL,
        y_value FLOAT NOT NULL
    )
""")
conn.commit()

# Исходные данные для интерполяции (пример)
x_data = np.array([0, 10, 20, 30, 40])
y_data = np.array([0, 100, 400, 900, 1600])

# Создание интерполяционной функции
interp_func = interp1d(x_data, y_data, kind='linear')

# Запуск замера времени
start_time = time.time()

# Буфер для хранения данных перед вставкой
batch_size = 1000
batch_data = []

# Выполнение расчетов и запись в базу данных
for x in np.arange(0, 40.01, 0.01):
    y = interp_func(x).item()  # Преобразование numpy.ndarray в float
    batch_data.append((float(x), float(y)))

    # Периодическая вставка данных в базу (каждые batch_size записей)
    if len(batch_data) >= batch_size:
        cursor.executemany("INSERT INTO interpolation_results (x_value, y_value) VALUES (%s, %s)", batch_data)
        conn.commit()  # Выполняем commit после каждой партии данных
        batch_data = []  # Очистка буфера

# Записываем оставшиеся данные, если есть
if batch_data:
    cursor.executemany("INSERT INTO interpolation_results (x_value, y_value) VALUES (%s, %s)", batch_data)
    conn.commit()

# Замер времени выполнения
end_time = time.time()
execution_time = end_time - start_time

print(f"Время выполнения: {execution_time:.4f} секунд")

# Закрытие соединения с БД
cursor.close()
conn.close()
