
"""
Компактное приложение для расчета интерполяции с использованием хранимой процедуры БД.
"""

import os
import csv
import time
import logging
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
import mysql.connector

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger('interpolation_app')


class DatabaseManager:
    """Класс для работы с базой данных и вызова хранимых процедур"""

    def __init__(self, host='localhost', port=3306, database='interpolation_db', user='user', password='password'):
        self.connection_params = {
            'host': host, 'port': port, 'database': database, 'user': user, 'password': password
        }
        self.connection = None
        self.cursor = None

    def connect(self):
        """Установка соединения с базой данных"""
        try:
            self.connection = mysql.connector.connect(**self.connection_params)
            if self.connection.is_connected():
                self.cursor = self.connection.cursor(dictionary=True)
                return True
        except Exception as e:
            logger.error(f"Ошибка при подключении к MySQL: {e}")
            return False

    def disconnect(self):
        """Закрытие соединения с базой данных"""
        if self.connection and self.connection.is_connected():
            if self.cursor: self.cursor.close()
            self.connection.close()

    def create_tables_if_not_exist(self):
        """Создание необходимых таблиц, если они не существуют"""
        try:
            if not self.connection or not self.connection.is_connected():
                if not self.connect(): return False

            # Таблица для точек данных
            self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS points_table (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    x DOUBLE NOT NULL,
                    y DOUBLE NOT NULL,
                    dataset_id VARCHAR(50) DEFAULT 'default'
                );
            """)

            # Таблица для результатов
            self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS interpolation_results (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    dataset_id VARCHAR(50) NOT NULL,
                    interpolation_type VARCHAR(50) NOT NULL,
                    x_target DOUBLE NOT NULL,
                    y_result DOUBLE,
                    error_code INT,
                    error_message VARCHAR(255)
                );
            """)

            self.connection.commit()
            return True
        except Exception as e:
            logger.error(f"Ошибка при создании таблиц: {e}")
            return False

    def insert_data_points(self, points, dataset_id='default'):
        """Добавление точек данных в таблицу"""
        try:
            if not self.connection or not self.connection.is_connected():
                if not self.connect(): return False

            # Удаляем существующие точки с таким же dataset_id
            self.cursor.execute("DELETE FROM points_table WHERE dataset_id = %s;", (dataset_id,))

            # Добавляем новые точки
            self.cursor.executemany(
                "INSERT INTO points_table (x, y, dataset_id) VALUES (%s, %s, %s);",
                [(point[0], point[1], dataset_id) for point in points]
            )

            self.connection.commit()
            return True
        except Exception as e:
            logger.error(f"Ошибка при добавлении точек: {e}")
            return False

    def calculate_interpolation(self, interpolation_type, x_target, polynomial_degree=3, dataset_id='default'):
        """Вызов хранимой процедуры для расчета интерполяции"""
        try:
            if not self.connection or not self.connection.is_connected():
                if not self.connect(): return None, None, None

            # Вызываем хранимую процедуру
            self.cursor.callproc('CalculateInterpolation',
                                 [interpolation_type, 'points_table', 'x', 'y', x_target, polynomial_degree, 0, 0, ''])

            # Получаем результаты
            result_value = error_code = error_message = None
            for result in self.cursor.stored_results():
                row = result.fetchone()
                if row:
                    result_value = row['result_value']
                    error_code = row['error_code']
                    error_message = row['error_message']

            # Сохраняем результат
            self.cursor.execute(
                """INSERT INTO interpolation_results 
                   (dataset_id, interpolation_type, x_target, y_result, error_code, error_message)
                   VALUES (%s, %s, %s, %s, %s, %s);""",
                (dataset_id, interpolation_type, x_target, result_value, error_code, error_message)
            )

            self.connection.commit()
            return result_value, error_code, error_message
        except Exception as e:
            logger.error(f"Ошибка при вызове процедуры интерполяции: {e}")
            return None, -1, str(e)


class InterpolationApp:
    """Основной класс приложения для интерполяции данных"""

    def __init__(self):
        self.db_manager = DatabaseManager()

        # Создаем таблицы при запуске
        if not self.db_manager.create_tables_if_not_exist():
            messagebox.showerror("Ошибка БД", "Не удалось создать таблицы. Проверьте настройки подключения.")

        # Текущий набор данных
        self.current_dataset_id = 'default'
        self.current_points = []

        # Создание GUI
        self.root = tk.Tk()
        self.root.title("Интерполяция данных")
        self.root.geometry("1000x600")

        self.create_widgets()

        # Генерация начальных данных
        self.generate_data()

    def create_widgets(self):
        """Создание виджетов интерфейса"""
        # Основной фрейм
        main_frame = ttk.Frame(self.root, padding=10)
        main_frame.pack(fill=tk.BOTH, expand=True)

        # Верхняя панель с кнопками
        top_frame = ttk.Frame(main_frame)
        top_frame.pack(fill=tk.X, pady=5)

        ttk.Button(top_frame, text="Генерировать данные", command=self.generate_data).pack(side=tk.LEFT, padx=5)
        ttk.Button(top_frame, text="Загрузить из CSV", command=self.load_from_csv).pack(side=tk.LEFT, padx=5)

        # Фрейм для настроек и графика
        content_frame = ttk.Frame(main_frame)
        content_frame.pack(fill=tk.BOTH, expand=True, pady=5)

        # Левая панель с настройками
        left_frame = ttk.Frame(content_frame, width=250)
        left_frame.pack(side=tk.LEFT, fill=tk.Y, padx=5, pady=5)
        left_frame.pack_propagate(False)

        # Настройки генерации данных
        data_frame = ttk.LabelFrame(left_frame, text="Генерация данных", padding=10)
        data_frame.pack(fill=tk.X, pady=5)

        ttk.Label(data_frame, text="Тип данных:").grid(row=0, column=0, sticky=tk.W, pady=2)
        self.data_type_var = tk.StringVar(value="linear")
        data_type_combo = ttk.Combobox(data_frame, textvariable=self.data_type_var)
        data_type_combo['values'] = ('linear', 'polynomial')
        data_type_combo.grid(row=0, column=1, sticky=tk.W, pady=2)

        ttk.Label(data_frame, text="Количество точек:").grid(row=1, column=0, sticky=tk.W, pady=2)
        self.num_points_var = tk.StringVar(value="10")
        ttk.Entry(data_frame, textvariable=self.num_points_var, width=10).grid(row=1, column=1, sticky=tk.W, pady=2)

        ttk.Button(data_frame, text="Сгенерировать", command=self.generate_data).grid(row=2, column=0, columnspan=2,
                                                                                      pady=5)

        # Настройки интерполяции
        interp_frame = ttk.LabelFrame(left_frame, text="Интерполяция", padding=10)
        interp_frame.pack(fill=tk.X, pady=5)

        ttk.Label(interp_frame, text="Тип интерполяции:").grid(row=0, column=0, sticky=tk.W, pady=2)
        self.interp_type_var = tk.StringVar(value="linear")
        interp_type_combo = ttk.Combobox(interp_frame, textvariable=self.interp_type_var)
        interp_type_combo['values'] = ('linear', 'polynomial', 'spline', 'lagrange')
        interp_type_combo.grid(row=0, column=1, sticky=tk.W, pady=2)

        ttk.Label(interp_frame, text="Степень полинома:").grid(row=1, column=0, sticky=tk.W, pady=2)
        self.poly_degree_var = tk.StringVar(value="3")
        ttk.Entry(interp_frame, textvariable=self.poly_degree_var, width=10).grid(row=1, column=1, sticky=tk.W, pady=2)

        ttk.Label(interp_frame, text="Целевая точка X:").grid(row=2, column=0, sticky=tk.W, pady=2)
        self.x_target_var = tk.StringVar(value="5.0")
        ttk.Entry(interp_frame, textvariable=self.x_target_var, width=10).grid(row=2, column=1, sticky=tk.W, pady=2)

        ttk.Button(interp_frame, text="Рассчитать", command=self.calculate_interpolation).grid(row=3, column=0,
                                                                                               columnspan=2, pady=5)

        # Результаты
        result_frame = ttk.LabelFrame(left_frame, text="Результаты", padding=10)
        result_frame.pack(fill=tk.X, pady=5)

        ttk.Label(result_frame, text="Значение Y:").grid(row=0, column=0, sticky=tk.W, pady=2)
        self.y_result_var = tk.StringVar(value="-")
        ttk.Label(result_frame, textvariable=self.y_result_var).grid(row=0, column=1, sticky=tk.W, pady=2)

        ttk.Label(result_frame, text="Статус:").grid(row=1, column=0, sticky=tk.W, pady=2)
        self.status_var = tk.StringVar(value="Готов к работе")
        ttk.Label(result_frame, textvariable=self.status_var).grid(row=1, column=1, sticky=tk.W, pady=2)

        # Правая панель с графиком
        right_frame = ttk.Frame(content_frame)
        right_frame.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True, padx=5, pady=5)

        # Фрейм для графика
        plot_frame = ttk.LabelFrame(right_frame, text="График", padding=10)
        plot_frame.pack(fill=tk.BOTH, expand=True)

        # Создаем холст для графика
        self.fig = plt.figure(figsize=(8, 5))
        self.ax = self.fig.add_subplot(111)
        self.ax.grid(True)
        self.ax.set_xlabel('X')
        self.ax.set_ylabel('Y')
        self.ax.set_title('Интерполяция данных')

        self.canvas = FigureCanvasTkAgg(self.fig, master=plot_frame)
        self.canvas.draw()
        self.canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

    def generate_data(self):
        """Генерация тестовых данных"""
        try:
            data_type = self.data_type_var.get()
            num_points = int(self.num_points_var.get())

            # Генерируем данные
            if data_type == 'linear':
                a = np.random.uniform(0.5, 2.0)  # Наклон
                b = np.random.uniform(-5, 5)  # Смещение

                x_values = np.linspace(0, 10, num_points)
                y_values = a * x_values + b + np.random.normal(0, 0.1, num_points)

                self.current_points = list(zip(x_values, y_values))

            elif data_type == 'polynomial':
                coefficients = [np.random.uniform(-2, 2) for _ in range(4)]  # Степень 3

                x_values = np.linspace(0, 10, num_points)
                y_values = np.zeros_like(x_values)

                for i, coef in enumerate(coefficients):
                    y_values += coef * np.power(x_values, i)

                y_values += np.random.normal(0, 0.1, num_points)
                self.current_points = list(zip(x_values, y_values))

            # Генерируем новый ID для набора данных
            self.current_dataset_id = f"{data_type}_{time.strftime('%Y%m%d%H%M%S')}"

            # Сохраняем данные в БД
            self.db_manager.insert_data_points(self.current_points, self.current_dataset_id)

            # Обновляем график
            self.update_plot()

            self.status_var.set(f"Данные готовы: {len(self.current_points)} точек")

        except Exception as e:
            logger.error(f"Ошибка при генерации данных: {e}")
            messagebox.showerror("Ошибка", f"Не удалось сгенерировать данные: {str(e)}")

    def load_from_csv(self):
        """Загрузка данных из CSV файла"""
        try:
            file_path = filedialog.askopenfilename(
                title="Выберите CSV файл",
                filetypes=[("CSV files", "*.csv"), ("All files", "*.*")]
            )

            if not file_path:
                return

            # Загружаем данные из файла
            data = []
            with open(file_path, 'r', newline='', encoding='utf-8') as csvfile:
                reader = csv.reader(csvfile)
                header = next(reader)  # Пропускаем заголовок

                # Используем первые два столбца
                for row in reader:
                    try:
                        x = float(row[0])
                        y = float(row[1])
                        data.append((x, y))
                    except (ValueError, IndexError):
                        pass

            if not data:
                messagebox.showerror("Ошибка", "Не удалось загрузить данные из файла или файл пуст")
                return

            self.current_points = data

            # Генерируем новый ID для набора данных
            file_name = os.path.basename(file_path)
            self.current_dataset_id = f"csv_{file_name.split('.')[0]}_{time.strftime('%Y%m%d%H%M%S')}"

            # Сохраняем данные в БД
            self.db_manager.insert_data_points(self.current_points, self.current_dataset_id)

            # Обновляем график
            self.update_plot()

            self.status_var.set(f"Данные готовы: {len(self.current_points)} точек")

        except Exception as e:
            logger.error(f"Ошибка при загрузке данных из CSV: {e}")
            messagebox.showerror("Ошибка", f"Не удалось загрузить данные: {str(e)}")

    def update_plot(self):
        """Обновление графика с текущими данными"""
        try:
            # Очищаем график
            self.ax.clear()
            self.ax.grid(True)
            self.ax.set_xlabel('X')
            self.ax.set_ylabel('Y')
            self.ax.set_title('Интерполяция данных')

            # Отображаем точки данных
            if self.current_points:
                x_values, y_values = zip(*self.current_points)
                self.ax.scatter(x_values, y_values, color='blue', label='Исходные точки', s=30)
                self.ax.legend()

            # Обновляем холст
            self.canvas.draw()

        except Exception as e:
            logger.error(f"Ошибка при обновлении графика: {e}")
            messagebox.showerror("Ошибка", f"Не удалось обновить график: {str(e)}")

    def calculate_interpolation(self):
        """Расчет интерполяции с использованием хранимой процедуры"""
        try:
            if not self.current_points:
                messagebox.showerror("Ошибка", "Сначала необходимо сгенерировать или загрузить данные")
                return

            interp_type = self.interp_type_var.get()
            poly_degree = int(self.poly_degree_var.get())
            x_target = float(self.x_target_var.get())

            # Получаем результат для целевой точки
            y_result, error_code, error_message = self.db_manager.calculate_interpolation(
                interp_type, x_target, poly_degree, self.current_dataset_id
            )

            if y_result is not None:
                self.y_result_var.set(f"{y_result:.6f}")

                if error_code > 0:
                    self.status_var.set(f"Предупреждение: {error_message}")
                else:
                    self.status_var.set(f"Интерполяция успешно выполнена")

                # Обновляем график
                self.ax.clear()
                self.ax.grid(True)
                self.ax.set_xlabel('X')
                self.ax.set_ylabel('Y')
                self.ax.set_title(f'Интерполяция данных ({interp_type})')

                # Отображаем исходные точки
                x_values, y_values = zip(*self.current_points)
                self.ax.scatter(x_values, y_values, color='blue', label='Исходные точки', s=30)

                # Вычисляем и отображаем интерполяцию
                x_min, x_max = min(x_values), max(x_values)
                range_x = x_max - x_min
                x_min -= range_x * 0.1
                x_max += range_x * 0.1

                x_interp = np.linspace(x_min, x_max, 100)
                y_interp = []

                for x in x_interp:
                    y, _, _ = self.db_manager.calculate_interpolation(
                        interp_type, x, poly_degree, self.current_dataset_id
                    )
                    y_interp.append(y if y is not None else np.nan)

                self.ax.plot(x_interp, y_interp, '-', label=f'Интерполяция ({interp_type})', linewidth=2)

                # Отмечаем целевую точку
                if not np.isnan(y_result):
                    self.ax.plot([x_target], [y_result], 'ro', markersize=8,
                                 label=f'Точка: ({x_target:.2f}, {y_result:.2f})')

                self.ax.legend()
                self.canvas.draw()

            else:
                self.y_result_var.set("Ошибка")
                self.status_var.set(f"Ошибка: {error_message}")
                messagebox.showerror("Ошибка", f"Не удалось выполнить интерполяцию: {error_message}")

        except Exception as e:
            logger.error(f"Ошибка при расчете интерполяции: {e}")
            messagebox.showerror("Ошибка", f"Не удалось выполнить интерполяцию: {str(e)}")

    def run(self):
        """Запуск приложения"""
        self.root.mainloop()
        self.db_manager.disconnect()


if __name__ == "__main__":
    app = InterpolationApp()
    app.run()