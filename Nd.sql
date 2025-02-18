CREATE SCHEMA IF NOT EXISTS kostya;

DO $$
BEGIN
    RAISE NOTICE 'Инициализация структуры базы данных meteo';
    
    -- Удаление существующих связей
    ALTER TABLE IF EXISTS kostya.measurement_input_params DROP CONSTRAINT IF EXISTS fk_measurement_type;
    ALTER TABLE IF EXISTS kostya.employees DROP CONSTRAINT IF EXISTS fk_military_rank;
    ALTER TABLE IF EXISTS kostya.measurement_batches DROP CONSTRAINT IF EXISTS fk_input_param;
    ALTER TABLE IF EXISTS kostya.measurement_batches DROP CONSTRAINT IF EXISTS fk_employee;
    
    -- Удаление существующих таблиц
    DROP TABLE IF EXISTS 
        kostya.measurement_input_params,
        kostya.measurement_batches,
        kostya.employees,
        kostya.measurement_types,
        kostya.military_ranks,
        kostya.temperature_corrections,
        kostya.calculated_temperature_corrections;
    
    -- Удаление последовательностей
    DROP SEQUENCE IF EXISTS 
        kostya.seq_measurement_input_params,
        kostya.seq_measurement_batches,
        kostya.seq_employees,
        kostya.seq_military_ranks,
        kostya.seq_measurement_types;
    
    RAISE NOTICE 'Удаление старых данных завершено';

    -- Создание таблицы воинских званий
    CREATE TABLE kostya.military_ranks (
        id SERIAL PRIMARY KEY,
        rank_description VARCHAR(255) NOT NULL
    );
    
    INSERT INTO kostya.military_ranks (rank_description) VALUES 
        ('Рядовой'), ('Лейтенант');
    
    -- Создание таблицы сотрудников
    CREATE TABLE kostya.employees (
        id SERIAL PRIMARY KEY,
        full_name TEXT NOT NULL,
        birth_date TIMESTAMP NOT NULL,
        military_rank_id INTEGER REFERENCES kostya.military_ranks(id)
    );
    
    INSERT INTO kostya.employees (full_name, birth_date, military_rank_id) VALUES
        ('Воловиков Александр Сергеевич', '1978-06-24', 2);
    
    -- Создание типов измерений
    CREATE TABLE kostya.measurement_types (
        id SERIAL PRIMARY KEY,
        short_name VARCHAR(50) NOT NULL,
        description TEXT NOT NULL
    );
    
    INSERT INTO kostya.measurement_types (short_name, description) VALUES
        ('ДМК', 'Десантный метео комплекс'),
        ('ВР', 'Ветровое ружье');
    
    -- Создание таблицы параметров измерений
    CREATE TABLE kostya.measurement_input_params (
        id SERIAL PRIMARY KEY,
        measurement_type_id INTEGER REFERENCES kostya.measurement_types(id),
        altitude NUMERIC(8,2) DEFAULT 0,
        temperature NUMERIC(8,2) DEFAULT 0,
        pressure NUMERIC(8,2) DEFAULT 0,
        wind_direction NUMERIC(8,2) DEFAULT 0,
        wind_speed NUMERIC(8,2) DEFAULT 0
    );
    
    INSERT INTO kostya.measurement_input_params (measurement_type_id, altitude, temperature, pressure, wind_direction, wind_speed) VALUES
        (1, 100, 12, 34, 0.2, 45);
    
    -- Создание таблицы истории измерений
    CREATE TABLE kostya.measurement_batches (
        id SERIAL PRIMARY KEY,
        employee_id INTEGER REFERENCES kostya.employees(id),
        input_param_id INTEGER REFERENCES kostya.measurement_input_params(id),
        start_time TIMESTAMP DEFAULT NOW()
    );
    
    INSERT INTO kostya.measurement_batches (employee_id, input_param_id) VALUES (1, 1);
    
    -- Создание таблицы температурных коррекций
    CREATE TABLE IF NOT EXISTS kostya.temperature_corrections (
        temperature NUMERIC(8,2) PRIMARY KEY,
        correction NUMERIC(8,2) NOT NULL
    );
    
    INSERT INTO kostya.temperature_corrections (temperature, correction) VALUES
        (0, 0.5), (5, 0.5), (10, 1), (20, 1), (25, 2), (30, 3.5), (40, 4.5);
    
    -- Установка связей
    ALTER TABLE kostya.measurement_batches ADD CONSTRAINT fk_employee FOREIGN KEY (employee_id) REFERENCES kostya.employees (id);
    ALTER TABLE kostya.measurement_batches ADD CONSTRAINT fk_input_param FOREIGN KEY (input_param_id) REFERENCES kostya.measurement_input_params (id);
    ALTER TABLE kostya.measurement_input_params ADD CONSTRAINT fk_measurement_type FOREIGN KEY (measurement_type_id) REFERENCES kostya.measurement_types (id);
    ALTER TABLE kostya.employees ADD CONSTRAINT fk_military_rank FOREIGN KEY (military_rank_id) REFERENCES kostya.military_ranks (id);
    
    RAISE NOTICE 'Структура базы данных успешно создана';
END $$;
