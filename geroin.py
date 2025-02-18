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

# Выполнение расчетов и запись в базу данных
for x in np.arange(0, 40.01, 0.01):
    y = interp_func(x).item()  # Преобразование numpy.ndarray в float
    cursor.execute("INSERT INTO interpolation_results (x_value, y_value) VALUES (%s, %s)", (float(x), float(y)))
    conn.commit()

# Замер времени выполнения
end_time = time.time()
execution_time = end_time - start_time

print(f"Время выполнения: {execution_time:.4f} секунд")

# Закрытие соединения с БД
cursor.close()
conn.close()
