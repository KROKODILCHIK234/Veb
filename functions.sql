-- 1. Создание таблицы настроек измерений
CREATE TABLE IF NOT EXISTS measure_settings (
    parameter_name TEXT PRIMARY KEY,
    min_value NUMERIC NOT NULL,
    max_value NUMERIC NOT NULL,
    unit TEXT NOT NULL
);

-- 2. Заполнение таблицы константами (если они еще не добавлены)
INSERT INTO measure_settings (parameter_name, min_value, max_value, unit) VALUES
    ('temperature', -58, 58, 'Celsius'),
    ('pressure', 500, 900, 'mmHg'),
    ('wind_direction', 0, 59, 'degrees')
ON CONFLICT (parameter_name) DO NOTHING;

-- 3. Создание пользовательского типа данных
CREATE TYPE measure_type AS (
    temperature NUMERIC,
    pressure NUMERIC,
    wind_direction INTEGER
);

-- 4. Функция проверки входных параметров с динамическими границами
CREATE OR REPLACE FUNCTION validate_measurements(
    temp NUMERIC,
    pres NUMERIC,
    wind_dir INTEGER
) RETURNS measure_type AS $$
DECLARE
    limits RECORD;
BEGIN
    -- Получаем границы всех параметров одним запросом
    SELECT
        (SELECT min_value FROM measure_settings WHERE parameter_name = 'temperature') AS min_temp,
        (SELECT max_value FROM measure_settings WHERE parameter_name = 'temperature') AS max_temp,
        (SELECT min_value FROM measure_settings WHERE parameter_name = 'pressure') AS min_pres,
        (SELECT max_value FROM measure_settings WHERE parameter_name = 'pressure') AS max_pres,
        (SELECT min_value FROM measure_settings WHERE parameter_name = 'wind_direction') AS min_wind,
        (SELECT max_value FROM measure_settings WHERE parameter_name = 'wind_direction') AS max_wind
    INTO limits;

    -- Проверка границ
    IF temp < limits.min_temp OR temp > limits.max_temp THEN
        RAISE EXCEPTION 'Температура выходит за границы (допустимый диапазон: % - %)', limits.min_temp, limits.max_temp;
    END IF;
    IF pres < limits.min_pres OR pres > limits.max_pres THEN
        RAISE EXCEPTION 'Давление выходит за границы (допустимый диапазон: % - %)', limits.min_pres, limits.max_pres;
    END IF;
    IF wind_dir < limits.min_wind OR wind_dir > limits.max_wind THEN
        RAISE EXCEPTION 'Направление ветра выходит за границы (допустимый диапазон: % - %)', limits.min_wind, limits.max_wind;
    END IF;

    RETURN (temp, pres, wind_dir)::measure_type;
END;
$$ LANGUAGE plpgsql;

-- 5. Функция расчета среднего значения измерений
CREATE OR REPLACE FUNCTION calculate_meteo_average(user_id INT)
RETURNS measure_type AS $$
DECLARE
    avg_values measure_type;
BEGIN
    SELECT
        AVG(temperature),
        AVG(pressure),
        ROUND(AVG(wind_direction))
    INTO avg_values
    FROM measurements
    WHERE employee_id = user_id;

    RETURN avg_values;
END;
$$ LANGUAGE plpgsql;

-- 6. Создание основной таблицы с измерениями
CREATE TABLE IF NOT EXISTS measurements (
    id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL,
    temperature NUMERIC NOT NULL,
    pressure NUMERIC NOT NULL,
    wind_direction INTEGER NOT NULL,
    measurement_time TIMESTAMP DEFAULT NOW()
);

-- 7. Таблица сотрудников
CREATE TABLE IF NOT EXISTS employees (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

-- 8. Генерация тестовых данных
DO $$
DECLARE
    emp_id INT;
    temp NUMERIC;
    pres NUMERIC;
    wind_dir INTEGER;
BEGIN
    -- Добавляем 5 сотрудников и генерируем данные
    FOR emp_id IN 1..5 LOOP
        INSERT INTO employees (name) VALUES ('Employee ' || emp_id) RETURNING id INTO emp_id;

        FOR _ IN 1..100 LOOP
            temp := -58 + RANDOM() * 116;  -- (-58 до 58)
            pres := 500 + RANDOM() * 400;  -- (500 до 900)
            wind_dir := FLOOR(RANDOM() * 60);

            BEGIN
                INSERT INTO measurements (employee_id, temperature, pressure, wind_direction)
                VALUES (emp_id, temp, pres, wind_dir);
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE NOTICE 'Ошибка при вставке измерения: %, %, %', temp, pres, wind_dir;
            END;
        END LOOP;
    END LOOP;
END $$;