BEGIN;

    ALTER TABLE IF EXISTS public.measurment_input_params DROP CONSTRAINT IF EXISTS measurment_type_id_fk;
    ALTER TABLE IF EXISTS public.employees DROP CONSTRAINT IF EXISTS military_rank_id_fk;
    ALTER TABLE IF EXISTS public.measurment_baths DROP CONSTRAINT IF EXISTS measurment_input_param_id_fk;
    ALTER TABLE IF EXISTS public.measurment_baths DROP CONSTRAINT IF EXISTS emploee_id_fk;

    DROP TABLE IF EXISTS public.measurment_input_params;
    DROP TABLE IF EXISTS public.measurment_baths;
    DROP TABLE IF EXISTS public.employees;
    DROP TABLE IF EXISTS public.measurment_types;
    DROP TABLE IF EXISTS public.military_ranks;
    DROP TABLE IF EXISTS public.measurment_settings;
    DROP TABLE IF EXISTS public.calc_temperatures_correction;
    DROP TABLE IF EXISTS public.constants;
    DROP TABLE IF EXISTS public.temperature_deviations;
    DROP TABLE IF EXISTS public.wind_corrections;

    DROP SEQUENCE IF EXISTS public.measurment_input_params_seq;
    DROP SEQUENCE IF EXISTS public.measurment_baths_seq;
    DROP SEQUENCE IF EXISTS public.employees_seq;
    DROP SEQUENCE IF EXISTS public.military_ranks_seq;
    DROP SEQUENCE IF EXISTS public.measurment_types_seq;

    DROP TYPE IF EXISTS public.interpolation_type CASCADE;
    DROP TYPE IF EXISTS public.input_params CASCADE;
    DROP TYPE IF EXISTS public.measure_type CASCADE;

    RAISE NOTICE ;
COMMIT;

BEGIN;
    RAISE NOTICE ;

    CREATE TYPE public.interpolation_type AS (
        x0 NUMERIC(8,2),
        x1 NUMERIC(8,2),
        y0 NUMERIC(8,2),
        y1 NUMERIC(8,2)
    );

    CREATE TYPE public.input_params AS (
        height NUMERIC(8,2),
        temperature NUMERIC(8,2),
        pressure NUMERIC(8,2),
        wind_direction NUMERIC(8,2),
        wind_speed NUMERIC(8,2),
        bullet_demolition_range NUMERIC(8,2)
    );


    CREATE TYPE public.measure_type AS (
        param NUMERIC,
        ttype TEXT
    );

    RAISE NOTICE ;
COMMIT;

BEGIN;
    RAISE NOTICE ;

    CREATE TABLE public.military_ranks (
        id INTEGER PRIMARY KEY NOT NULL,
        description VARCHAR(255) NOT NULL
    );

    CREATE SEQUENCE public.military_ranks_seq START 3;
    ALTER TABLE public.military_ranks ALTER COLUMN id SET DEFAULT nextval('public.military_ranks_seq');

    INSERT INTO public.military_ranks(id, description)
    VALUES (1, 'Рядовой'), (2, 'Лейтенант');

    RAISE NOTICE ;
COMMIT;

BEGIN;
    RAISE NOTICE ;

    CREATE TABLE public.employees (
        id INTEGER PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        birthday TIMESTAMP,
        military_rank_id INTEGER
    );

    CREATE SEQUENCE public.employees_seq START 2;
    ALTER TABLE public.employees ALTER COLUMN id SET DEFAULT nextval('public.employees_seq');

    INSERT INTO public.employees(id, name, birthday, military_rank_id)
    VALUES (1, 'Воловиков Александр Сергеевич', '1978-06-24', 2);

    RAISE NOTICE 'Таблица employees создана успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание таблицы типов измерительных устройств...';

    CREATE TABLE public.measurment_types (
        id INTEGER PRIMARY KEY NOT NULL,
        short_name VARCHAR(50) NOT NULL,
        description TEXT
    );

    CREATE SEQUENCE public.measurment_types_seq START 3;
    ALTER TABLE public.measurment_types ALTER COLUMN id SET DEFAULT nextval('public.measurment_types_seq');

    INSERT INTO public.measurment_types(id, short_name, description)
    VALUES (1, 'ДМК', 'Десантный метео комплекс'),
           (2, 'ВР', 'Ветровое ружье');

    RAISE NOTICE 'Таблица measurment_types создана успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание таблицы параметров измерений...';

    CREATE TABLE public.measurment_input_params (
        id INTEGER PRIMARY KEY NOT NULL,
        measurment_type_id INTEGER NOT NULL,
        height NUMERIC(8,2) DEFAULT 0,
        temperature NUMERIC(8,2) DEFAULT 0,
        pressure NUMERIC(8,2) DEFAULT 0,
        wind_direction NUMERIC(8,2) DEFAULT 0,
        wind_speed NUMERIC(8,2) DEFAULT 0,
        bullet_demolition_range NUMERIC(8,2) DEFAULT 0
    );

    CREATE SEQUENCE public.measurment_input_params_seq START 2;
    ALTER TABLE public.measurment_input_params ALTER COLUMN id SET DEFAULT nextval('public.measurment_input_params_seq');

    INSERT INTO public.measurment_input_params(id, measurment_type_id, height, temperature, pressure, wind_direction, wind_speed)
    VALUES (1, 1, 100, 12, 34, 0.2, 45);

    RAISE NOTICE 'Таблица measurment_input_params создана успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание таблицы истории измерений...';

    CREATE TABLE public.measurment_baths (
        id INTEGER PRIMARY KEY NOT NULL,
        emploee_id INTEGER NOT NULL,
        measurment_input_param_id INTEGER NOT NULL,
        started TIMESTAMP DEFAULT now()
    );

    CREATE SEQUENCE public.measurment_baths_seq START 2;
    ALTER TABLE public.measurment_baths ALTER COLUMN id SET DEFAULT nextval('public.measurment_baths_seq');

    INSERT INTO public.measurment_baths(id, emploee_id, measurment_input_param_id)
    VALUES (1, 1, 1);

    RAISE NOTICE 'Таблица measurment_baths создана успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание таблицы настроек измерений...';

    CREATE TABLE public.measurment_settings (
        key VARCHAR(100) PRIMARY KEY NOT NULL,
        value VARCHAR(255),
        description TEXT
    );

    INSERT INTO public.measurment_settings(key, value, description)
    VALUES ('min_temperature', '-58', 'Минимальное значение температуры'),
           ('max_temperature', '58', 'Максимальное значение температуры'),
           ('min_pressure', '500', 'Минимальное значение давления'),
           ('max_pressure', '900', 'Максимальное значение давления'),
           ('min_wind_direction', '0', 'Минимальное значение направления ветра'),
           ('max_wind_direction', '59', 'Максимальное значение направления ветра'),
           ('calc_table_temperature', '15.9', 'Табличное значение температуры'),
           ('calc_table_pressure', '750', 'Табличное значение наземного давления'),
           ('min_height', '-10000', 'Минимальная высота'),
           ('max_height', '10000', 'Максимальная высота'),
           ('min_wind_speed', '0', 'Минимальная скорость ветра'),
           ('max_wind_speed', '15', 'Максимальная скорость ветра'),
           ('min_bullet_demolition_range', '0', 'Минимальная дальность сноса пуль'),
           ('max_bullet_demolition_range', '150', 'Максимальная дальность сноса пуль');

    RAISE NOTICE 'Таблица measurment_settings создана успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание таблицы температурных поправок...';

    CREATE TABLE public.calc_temperatures_correction (
        temperature NUMERIC(8,2) PRIMARY KEY,
        correction NUMERIC(8,2)
    );

    INSERT INTO public.calc_temperatures_correction(temperature, correction)
    VALUES (0, 0.5), (5, 0.5), (10, 1), (20, 1), (25, 2), (30, 3.5), (40, 4.5);

    RAISE NOTICE 'Таблица calc_temperatures_correction создана успешно';
COMMIT;


BEGIN;
    RAISE NOTICE 'Создание таблицы констант...';

    CREATE TABLE public.constants (
        key VARCHAR(30) PRIMARY KEY NOT NULL,
        value TEXT NOT NULL
    );

    CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_key
        ON public.constants USING btree (key ASC NULLS LAST);

    INSERT INTO public.constants(key, value)
    VALUES ('const_pressure', '750'), ('const_temperature', '15.9');

    RAISE NOTICE 'Таблица constants создана успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание таблицы отклонений температуры...';

    CREATE TABLE public.temperature_deviations (
        height INTEGER PRIMARY KEY,
        dev_1 NUMERIC,
        dev_2 NUMERIC,
        dev_3 NUMERIC,
        dev_4 NUMERIC,
        dev_5 NUMERIC,
        dev_6 NUMERIC,
        dev_7 NUMERIC,
        dev_8 NUMERIC,
        dev_9 NUMERIC,
        dev_10 NUMERIC,
        dev_20 NUMERIC,
        dev_30 NUMERIC,
        dev_40 NUMERIC,
        dev_50 NUMERIC
    );

    INSERT INTO public.temperature_deviations VALUES
        (200, -1, -2, -3, -4, -5, -6, -7, -8, -8, -9, -20, -29, -39, -49),
        (400, -1, -2, -3, -4, -5, -6, -6, -7, -8, -9, -19, -29, -38, -48),
        (800, -1, -2, -3, -4, -5, -6, -6, -7, -7, -8, -18, -28, -37, -46),
        (1200, -1, -2, -3, -4, -5, -5, -5, -6, -7, -8, -17, -26, -35, -44),
        (1600, -1, -2, -3, -3, -4, -4, -5, -6, -7, -7, -17, -25, -34, -42),
        (2000, -1, -2, -3, -3, -4, -4, -5, -6, -6, -7, -16, -24, -32, -40),
        (2400, -1, -2, -2, -3, -4, -4, -5, -5, -6, -7, -15, -23, -31, -38),
        (3000, -1, -2, -2, -3, -4, -4, -4, -5, -5, -6, -15, -22, -30, -37),
        (4000, -1, -2, -2, -3, -4, -4, -4, -4, -5, -6, -14, -20, -27, -34);

    RAISE NOTICE 'Таблица temperature_deviations создана успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание таблицы корректировок для расчета среднего ветра...';

    CREATE TABLE public.wind_corrections (
        height INTEGER PRIMARY KEY,
        correction_0_5 NUMERIC(8,2),
        correction_6_10 NUMERIC(8,2),
        correction_11_15 NUMERIC(8,2),
        correction_16_20 NUMERIC(8,2),
        correction_21_25 NUMERIC(8,2)
    );

    INSERT INTO public.wind_corrections (height, correction_0_5, correction_6_10, correction_11_15, correction_16_20, correction_21_25)
    VALUES
        (200, 1.0, 1.5, 2.0, 2.5, 3.0),
        (400, 1.2, 1.7, 2.2, 2.7, 3.2),
        (800, 1.4, 1.9, 2.4, 2.9, 3.4),
        (1200, 1.6, 2.1, 2.6, 3.1, 3.6),
        (1600, 1.8, 2.3, 2.8, 3.3, 3.8),
        (2000, 2.0, 2.5, 3.0, 3.5, 4.0),
        (2400, 2.2, 2.7, 3.2, 3.7, 4.2),
        (3000, 2.4, 2.9, 3.4, 3.9, 4.4),
        (4000, 2.6, 3.1, 3.6, 4.1, 4.6);

    RAISE NOTICE 'Таблица wind_corrections создана успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание внешних ключей...';

    ALTER TABLE public.employees
    ADD CONSTRAINT military_rank_id_fk
    FOREIGN KEY (military_rank_id)
    REFERENCES public.military_ranks (id);

    ALTER TABLE public.measurment_input_params
    ADD CONSTRAINT measurment_type_id_fk
    FOREIGN KEY (measurment_type_id)
    REFERENCES public.measurment_types (id);

    ALTER TABLE public.measurment_baths
    ADD CONSTRAINT emploee_id_fk
    FOREIGN KEY (emploee_id)
    REFERENCES public.employees (id);

    ALTER TABLE public.measurment_baths
    ADD CONSTRAINT measurment_input_param_id_fk
    FOREIGN KEY (measurment_input_param_id)
    REFERENCES public.measurment_input_params (id);

    RAISE NOTICE 'Внешние ключи созданы успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание функции форматирования даты...';

    CREATE OR REPLACE FUNCTION public.fn_calc_header_period(
        par_period TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    )
    RETURNS TEXT
    LANGUAGE SQL
    AS $$
        SELECT
            (CASE WHEN EXTRACT(day FROM par_period) < 10 THEN '0' ELSE '' END ||
            EXTRACT(day FROM par_period)::TEXT) ||
            (CASE WHEN EXTRACT(hour FROM par_period) < 10 THEN '0' ELSE '' END ||
            EXTRACT(hour FROM par_period)::TEXT) ||
            LEFT(CASE WHEN EXTRACT(minute FROM par_period) < 10 THEN '0'
                ELSE EXTRACT(minute FROM par_period)::TEXT END, 1);
    $$;

    COMMENT ON FUNCTION public.fn_calc_header_period IS 'Формирует дату в специальном формате для заголовка метеосводки';

    RAISE NOTICE 'Функция fn_calc_header_period создана успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание функции форматирования высоты...';

    CREATE OR REPLACE FUNCTION public.fn_calc_header_height(
        par_height INTEGER
    )
    RETURNS TEXT
    LANGUAGE PLPGSQL
    AS $$
    DECLARE
        var_result TEXT;
    BEGIN
        IF par_height < -10000 OR par_height > 10000 THEN
            RAISE EXCEPTION 'Высота % вне допустимого диапазона (-10000..10000 м)', par_height;
        END IF;

        var_result := LPAD(ABS(par_height)::TEXT, 4, '0');
        RETURN var_result;
    END;
    $$;

    COMMENT ON FUNCTION public.fn_calc_header_height IS 'Форматирует высоту для заголовка метеосводки';

    RAISE NOTICE 'Функция fn_calc_header_height создана успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание функции проверки параметров измерений...';

    CREATE OR REPLACE FUNCTION public.get_measure_setting(
        type_param VARCHAR,
        value_param NUMERIC
    )
    RETURNS public.measure_type
    LANGUAGE PLPGSQL
    AS $$
    DECLARE
        min_val NUMERIC;
        max_val NUMERIC;
        result public.measure_type;
    BEGIN
        EXECUTE format('SELECT value::NUMERIC FROM public.measurment_settings WHERE key = %L',
                      'min_' || LOWER(type_param)) INTO min_val;
        EXECUTE format('SELECT value::NUMERIC FROM public.measurment_settings WHERE key = %L',
                      'max_' || LOWER(type_param)) INTO max_val;

        IF min_val IS NULL OR max_val IS NULL THEN
            RAISE EXCEPTION 'Параметр % не найден в настройках', type_param;
        END IF;

        IF value_param IS NULL THEN
            RAISE EXCEPTION 'Значение не может быть NULL';
        END IF;

        IF value_param < min_val OR value_param > max_val THEN
            RETURN NULL;
        END IF;

        result.param := value_param;
        result.ttype := type_param;
        RETURN result;
    END;
    $$;

    COMMENT ON FUNCTION public.get_measure_setting IS 'Проверяет соответствие значения параметра допустимому диапазону';

    RAISE NOTICE 'Функция get_measure_setting создана успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание функции интерполяции температурной поправки...';

    CREATE OR REPLACE FUNCTION public.fn_calc_temperature_interpolation(
        par_temperature NUMERIC(8,2)
    )
    RETURNS NUMERIC
    LANGUAGE PLPGSQL
    AS $$
    DECLARE
        var_interpolation public.interpolation_type;
        var_result NUMERIC(8,2) := 0;
        var_min_temparure NUMERIC(8,2) := 0;
        var_max_temperature NUMERIC(8,2) := 0;
        var_denominator NUMERIC(8,2) := 0;
    BEGIN
        RAISE NOTICE 'Расчет интерполяции для температуры %', par_temperature;

        SELECT correction INTO var_result
        FROM public.calc_temperatures_correction
        WHERE temperature = par_temperature;

        IF FOUND THEN
            RETURN var_result;
        END IF;

        SELECT MIN(temperature), MAX(temperature)
        INTO var_min_temparure, var_max_temperature
        FROM public.calc_temperatures_correction;

        IF par_temperature < var_min_temparure OR par_temperature > var_max_temperature THEN
            RAISE EXCEPTION 'Температура % выходит за пределы диапазона поправок [%, %]',
                par_temperature, var_min_temparure, var_max_temperature;
        END IF;

        SELECT
            t1.temperature, t1.correction, t2.temperature, t2.correction
        INTO
            var_interpolation.x0, var_interpolation.y0, var_interpolation.x1, var_interpolation.y1
        FROM
            (SELECT temperature, correction
             FROM public.calc_temperatures_correction
             WHERE temperature <= par_temperature
             ORDER BY temperature DESC
             LIMIT 1) t1,
            (SELECT temperature, correction
             FROM public.calc_temperatures_correction
             WHERE temperature >= par_temperature
             ORDER BY temperature ASC
             LIMIT 1) t2;

        RAISE NOTICE 'Граничные значения: x0=%, y0=%, x1=%, y1=%',
            var_interpolation.x0, var_interpolation.y0, var_interpolation.x1, var_interpolation.y1;

        var_denominator := var_interpolation.x1 - var_interpolation.x0;

        IF var_denominator = 0 THEN
            RAISE EXCEPTION 'Деление на ноль при интерполяции';
        END IF;

        var_result := var_interpolation.y0 +
                      (par_temperature - var_interpolation.x0) *
                      (var_interpolation.y1 - var_interpolation.y0) / var_denominator;

        RETURN ROUND(var_result, 2);
    END;
    $$;

    COMMENT ON FUNCTION public.fn_calc_temperature_interpolation IS 'Вычисляет температурную поправку методом линейной интерполяции';

    RAISE NOTICE 'Функция fn_calc_temperature_interpolation создана успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание функции расчета отклонения приземной виртуальной температуры...';

    CREATE OR REPLACE FUNCTION public.fn_calc_header_temperature(
        par_temperature NUMERIC(8,2)
    )
    RETURNS NUMERIC(8,2)
    LANGUAGE PLPGSQL
    AS $$
    DECLARE
        virtual_temperature NUMERIC(8,2) := 0;
        deltaTv NUMERIC(8,2) := 0;
        var_result NUMERIC(8,2) := 0;
    BEGIN
        IF par_temperature IS NULL THEN
            RAISE EXCEPTION 'Температура не может быть NULL';
        END IF;

        SELECT COALESCE(value::NUMERIC(8,2), 15.9)
        INTO virtual_temperature
        FROM public.measurment_settings
        WHERE key = 'calc_table_temperature';

        deltaTv := par_temperature +
            public.fn_calc_temperature_interpolation(par_temperature => par_temperature);

        var_result := ROUND(deltaTv - virtual_temperature, 1);

        RETURN var_result;
    END;
    $$;

    COMMENT ON FUNCTION public.fn_calc_header_temperature IS 'Рассчитывает отклонение приземной виртуальной температуры';

    RAISE NOTICE 'Функция fn_calc_header_temperature создана успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание функции расчета отклонения наземного давления...';

    CREATE OR REPLACE FUNCTION public.fn_calc_header_pressure(
        par_pressure NUMERIC(8,2)
    )
    RETURNS NUMERIC(8,2)
    LANGUAGE PLPGSQL
    AS $$
    DECLARE
        table_pressure NUMERIC(8,2);
    BEGIN
        IF par_pressure IS NULL THEN
            RAISE EXCEPTION 'Давление не может быть NULL';
        END IF;

        IF par_pressure < 500 OR par_pressure > 900 THEN
            RAISE EXCEPTION 'Давление % вне допустимого диапазона (500..900 мм рт.ст.)', par_pressure;
        END IF;

        SELECT COALESCE(value::NUMERIC(8,2), 750)
        INTO table_pressure
        FROM public.measurment_settings
        WHERE key = 'calc_table_pressure';

        RETURN ROUND(par_pressure - table_pressure, 1);
    END;
    $$;

    COMMENT ON FUNCTION public.fn_calc_header_pressure IS 'Рассчитывает отклонение наземного давления от табличного значения';

    RAISE NOTICE 'Функция fn_calc_header_pressure создана успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание функции форматирования метеопараметров...';

    CREATE OR REPLACE FUNCTION public.fn_format_meteo_header(
        par_pressure NUMERIC(8,2),
        par_temperature NUMERIC(8,2)
    )
    RETURNS TEXT
    LANGUAGE PLPGSQL
    AS $$
    DECLARE
        pressure_delta INTEGER;
        temp_delta INTEGER;
        pressure_str TEXT;
        temp_str TEXT;
    BEGIN
        IF par_pressure IS NULL OR par_temperature IS NULL THEN
            RAISE EXCEPTION 'Параметры не могут быть NULL';
        END IF;

        pressure_delta := ROUND(public.fn_calc_header_pressure(par_pressure))::INTEGER;
        temp_delta := ROUND(public.fn_calc_header_temperature(par_temperature))::INTEGER;

        IF pressure_delta < 0 THEN
            pressure_str := '5' || LPAD(ABS(pressure_delta)::TEXT, 2, '0');
        ELSE
            pressure_str := LPAD(pressure_delta::TEXT, 3, '0');
        END IF;

        IF temp_delta < 0 THEN
            temp_str := '5' || ABS(temp_delta)::TEXT;
        ELSE
            temp_str := LPAD(temp_delta::TEXT, 2, '0');
        END IF;

        RETURN pressure_str || temp_str;
    END;
    $$;

    COMMENT ON FUNCTION public.fn_format_meteo_header IS 'Форматирует метеопараметры для заголовка метеосводки';

    RAISE NOTICE 'Функция fn_format_meteo_header создана успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание функции проверки входных параметров измерений...';

    CREATE OR REPLACE FUNCTION public.fn_check_input_params(
        par_height NUMERIC(8,2),
        par_temperature NUMERIC(8,2),
        par_pressure NUMERIC(8,2),
        par_wind_direction NUMERIC(8,2),
        par_wind_speed NUMERIC(8,2),
        par_bullet_demolition_range NUMERIC(8,2)
    )
    RETURNS public.input_params
    LANGUAGE PLPGSQL
    AS $$
    DECLARE
        var_result public.input_params;
        min_val NUMERIC;
        max_val NUMERIC;
        param_name TEXT;
    BEGIN
        FOREACH param_name IN ARRAY ARRAY['height', 'temperature', 'pressure', 'wind_direction', 'wind_speed', 'bullet_demolition_range']
        LOOP
            EXECUTE format('SELECT %L::NUMERIC',
                CASE
                    WHEN param_name = 'height' THEN par_height
                    WHEN param_name = 'temperature' THEN par_temperature
                    WHEN param_name = 'pressure' THEN par_pressure
                    WHEN param_name = 'wind_direction' THEN par_wind_direction
                    WHEN param_name = 'wind_speed' THEN par_wind_speed
                    WHEN param_name = 'bullet_demolition_range' THEN par_bullet_demolition_range
                END) INTO min_val;

            EXECUTE format('SELECT value::NUMERIC FROM public.measurment_settings WHERE key = %L',
                          'min_' || param_name) INTO min_val;
            EXECUTE format('SELECT value::NUMERIC FROM public.measurment_settings WHERE key = %L',
                          'max_' || param_name) INTO max_val;

            EXECUTE format('SELECT %I', 'par_' || param_name) INTO var_result;

            IF var_result < min_val OR var_result > max_val THEN
                RAISE EXCEPTION '% % не укладывается в диапазон [%, %]',
                    INITCAP(param_name), var_result, min_val, max_val;
            END IF;

            EXECUTE format('var_result.%I := %L::NUMERIC', param_name, var_result);
        END LOOP;

        RETURN var_result;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Ошибка при проверке параметров: %', SQLERRM;
            RAISE;
    END;
    $$;

    COMMENT ON FUNCTION public.fn_check_input_params(NUMERIC(8,2), NUMERIC(8,2), NUMERIC(8,2), NUMERIC(8,2), NUMERIC(8,2), NUMERIC(8,2))
        IS 'Проверяет входные параметры измерений на соответствие диапазонам';

    CREATE OR REPLACE FUNCTION public.fn_check_input_params(
        par_param public.input_params
    )
    RETURNS public.input_params
    LANGUAGE PLPGSQL
    AS $$
    BEGIN
        RETURN public.fn_check_input_params(
            par_param.height,
            par_param.temperature,
            par_param.pressure,
            par_param.wind_direction,
            par_param.wind_speed,
            par_param.bullet_demolition_range
        );
    END;
    $$;

    COMMENT ON FUNCTION public.fn_check_input_params(public.input_params)
        IS 'Проверяет входные параметры измерений на соответствие диапазонам (перегрузка для типа input_params)';

    RAISE NOTICE 'Функция fn_check_input_params создана успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание функции для расчета отклонения температуры по высоте...';

    CREATE OR REPLACE FUNCTION public.get_deviation_value(
        p_height INTEGER,
        p_value INTEGER
    )
    RETURNS NUMERIC
    LANGUAGE PLPGSQL
    AS $$
    DECLARE
        closest_height INTEGER;
        col_name TEXT;
    BEGIN
        IF p_height IS NULL OR p_value IS NULL THEN
            RAISE EXCEPTION 'Высота и значение не могут быть NULL';
        END IF;

        SELECT height INTO closest_height
        FROM public.temperature_deviations
        ORDER BY ABS(height - p_height) ASC
        LIMIT 1;

        IF closest_height IS NULL THEN
            RAISE EXCEPTION 'Не найдены данные о температурных отклонениях для высоты %', p_height;
        END IF;

        IF p_value BETWEEN 1 AND 10 THEN
            col_name := 'dev_' || p_value;
        ELSIF p_value IN (20, 30, 40, 50) THEN
            col_name := 'dev_' || p_value;
        ELSE
            RAISE EXCEPTION 'Значение % должно быть в диапазоне 1-10 или одним из: 20, 30, 40, 50', p_value;
        END IF;

        RETURN (SELECT public.temperature_deviations.*::public.temperature_deviations ->> col_name
                FROM public.temperature_deviations
                WHERE height = closest_height)::NUMERIC;
    END;
    $;

    COMMENT ON FUNCTION public.get_deviation_value IS 'Получает значение отклонения температуры для заданной высоты и значения';

    RAISE NOTICE 'Функция get_deviation_value создана успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание функции для расчета температурного отклонения...';

    CREATE OR REPLACE FUNCTION public.calculate_temperature_deviation(
        p_height INTEGER,
        p_temperature NUMERIC
    )
    RETURNS NUMERIC[]
    LANGUAGE PLPGSQL
    AS $
    DECLARE
        v_tens INTEGER;
        v_ones INTEGER;
        v_dev_tens NUMERIC;
        v_dev_ones NUMERIC;
        v_result NUMERIC;
    BEGIN
        IF p_height IS NULL OR p_temperature IS NULL THEN
            RAISE EXCEPTION 'Высота и температура не могут быть NULL';
        END IF;

        v_tens := TRUNC(ABS(p_temperature) / 10) * 10;
        v_ones := ROUND(ABS(p_temperature) - v_tens);

        v_dev_tens := public.get_deviation_value(p_height,
                        CASE WHEN v_tens = 0 THEN 1 ELSE v_tens END);

        IF v_ones > 0 THEN
            v_dev_ones := public.get_deviation_value(p_height, v_ones);
        ELSE
            v_dev_ones := 0;
        END IF;

        v_result := v_dev_tens + v_dev_ones;

        IF p_temperature < 0 THEN
            v_result := ABS(v_result) + 50;
        END IF;

        RETURN ARRAY[v_tens, v_ones, v_dev_tens, v_dev_ones, v_result];
    END;
    $;

    COMMENT ON FUNCTION public.calculate_temperature_deviation IS 'Рассчитывает отклонение температуры по высоте';

    RAISE NOTICE 'Функция calculate_temperature_deviation создана успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание функции для полного расчета метео приближенного...';

    CREATE OR REPLACE FUNCTION public.fn_calc_header_meteo_avg(
        par_params public.input_params
    )
    RETURNS TEXT
    LANGUAGE PLPGSQL
    AS $
    DECLARE
        var_result TEXT;
        var_params public.input_params;
        var_period TEXT;
        var_height TEXT;
        var_pressure_temp TEXT;
    BEGIN
        BEGIN
            var_params := public.fn_check_input_params(par_params);
        EXCEPTION
            WHEN OTHERS THEN
                RAISE EXCEPTION 'Ошибка при проверке параметров: %', SQLERRM;
        END;

        var_period := public.fn_calc_header_period(NOW());
        var_height := public.fn_calc_header_height(ROUND(var_params.height)::INTEGER);
        var_pressure_temp := public.fn_format_meteo_header(var_params.pressure, var_params.temperature);

        var_result := var_period || var_height || var_pressure_temp;

        RETURN var_result;
    END;
    $;

    COMMENT ON FUNCTION public.fn_calc_header_meteo_avg IS 'Формирует полную строку метеосводки';

    RAISE NOTICE 'Функция fn_calc_header_meteo_avg создана успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Создание функций для генерации тестовых данных...';

    CREATE OR REPLACE FUNCTION public.fn_get_random_timestamp(
        par_min_value TIMESTAMP,
        par_max_value TIMESTAMP
    )
    RETURNS TIMESTAMP
    LANGUAGE PLPGSQL
    AS $
    BEGIN
        RETURN par_min_value + RANDOM() * (par_max_value - par_min_value);
    END;
    $;

    COMMENT ON FUNCTION public.fn_get_random_timestamp IS 'Генерирует случайную дату в заданном диапазоне';

    CREATE OR REPLACE FUNCTION public.fn_get_randon_integer(
        par_min_value INTEGER,
        par_max_value INTEGER
    )
    RETURNS INTEGER
    LANGUAGE PLPGSQL
    AS $
    BEGIN
        RETURN FLOOR((par_max_value + 1 - par_min_value) * RANDOM())::INTEGER + par_min_value;
    END;
    $;

    COMMENT ON FUNCTION public.fn_get_randon_integer IS 'Генерирует случайное целое число в заданном диапазоне';

    CREATE OR REPLACE FUNCTION public.fn_get_random_text(
        par_length INTEGER,
        par_list_of_chars TEXT DEFAULT 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюяABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_0123456789'
    )
    RETURNS TEXT
    LANGUAGE PLPGSQL
    AS $
    DECLARE
        var_len_of_list INTEGER := LENGTH(par_list_of_chars);
        var_position INTEGER;
        var_result TEXT := '';
        var_random_number INTEGER;
    BEGIN
        FOR var_position IN 1..par_length LOOP
            var_random_number := 1 + FLOOR(RANDOM() * var_len_of_list)::INTEGER;
            var_result := var_result || SUBSTR(par_list_of_chars, var_random_number, 1);
        END LOOP;

        RETURN var_result;
    END;
    $;

    COMMENT ON FUNCTION public.fn_get_random_text IS 'Генерирует случайный текст заданной длины';

    RAISE NOTICE 'Функции для генерации тестовых данных созданы успешно';
COMMIT;

BEGIN;
    RAISE NOTICE 'Генерация тестовых данных...';

    DO $
    DECLARE
        var_position INTEGER;
        var_emploee_ids INTEGER[] := ARRAY[]::INTEGER[];
        var_emploee_quantity INTEGER := 5;
        var_min_rank INTEGER;
        var_max_rank INTEGER;
        var_emploee_id INTEGER;
        var_current_emploee_id INTEGER;
        var_index INTEGER;
        var_measure_type_id INTEGER;
        var_measure_input_data_id INTEGER;
    BEGIN
        SELECT MIN(id), MAX(id)
        INTO var_min_rank, var_max_rank
        FROM public.military_ranks;

        FOR var_position IN 1..var_emploee_quantity LOOP
            INSERT INTO public.employees(
                name,
                birthday,
                military_rank_id
            )
            VALUES (
                public.fn_get_random_text(25),
                public.fn_get_random_timestamp('1978-01-01', '2000-01-01'),
                public.fn_get_randon_integer(var_min_rank, var_max_rank)
            )
            RETURNING id INTO var_emploee_id;

            var_emploee_ids := array_append(var_emploee_ids, var_emploee_id);
        END LOOP;

        RAISE NOTICE 'Сформированы тестовые пользователи: %', var_emploee_ids;

        FOREACH var_current_emploee_id IN ARRAY var_emploee_ids LOOP
            FOR var_index IN 1..100 LOOP
                var_measure_type_id := public.fn_get_randon_integer(1, 2);

                INSERT INTO public.measurment_input_params(
                    measurment_type_id,
                    height,
                    temperature,
                    pressure,
                    wind_direction,
                    wind_speed
                )
                VALUES (
                    var_measure_type_id,
                    public.fn_get_randon_integer(0, 600)::NUMERIC(8,2),
                    public.fn_get_randon_integer(0, 50)::NUMERIC(8,2),
                    public.fn_get_randon_integer(500, 850)::NUMERIC(8,2),
                    public.fn_get_randon_integer(0, 59)::NUMERIC(8,2),
                    public.fn_get_randon_integer(0, 59)::NUMERIC(8,2)
                )
                RETURNING id INTO var_measure_input_data_id;

                INSERT INTO public.measurment_baths(
                    emploee_id,
                    measurment_input_param_id,
                    started
                )
                VALUES (
                    var_current_emploee_id,
                    var_measure_input_data_id,
                    public.fn_get_random_timestamp('2025-02-01 00:00', '2025-02-05 00:00')
                );
            END LOOP;
        END LOOP;

        RAISE NOTICE 'Набор тестовых данных сформирован успешно';
    END;
    $;

    RAISE NOTICE 'Тестовые данные сгенерированы успешно';
COMMIT;

DO $
DECLARE
    var_pressure_value NUMERIC(8,2) := 0;
    var_temperature_value NUMERIC(8,2) := 0;
    var_input_params public.input_params;
    var_meteo_string TEXT;
BEGIN
    RAISE NOTICE '====================================';
    RAISE NOTICE 'Примеры использования функций';
    RAISE NOTICE '====================================';

    var_pressure_value := public.fn_calc_header_pressure(743);
    var_temperature_value := public.fn_calc_header_temperature(23);

    RAISE NOTICE 'Отклонение давления: %', var_pressure_value;
    RAISE NOTICE 'Отклонение температуры: %', var_temperature_value;

    RAISE NOTICE 'Форматированные параметры давления и температуры: %',
        public.fn_format_meteo_header(743, 23);

    var_input_params.height := 340;
    var_input_params.temperature := 23;
    var_input_params.pressure := 743;
    var_input_params.wind_direction := 30;
    var_input_params.wind_speed := 5;

    var_meteo_string := public.fn_calc_header_meteo_avg(var_input_params);

    RAISE NOTICE 'Полная метеосводка: %', var_meteo_string;
    RAISE NOTICE '====================================';
END;
$;

CREATE OR REPLACE FUNCTION public.fn_get_wind_group(
    par_wind_speed NUMERIC(8,2)
)
RETURNS TEXT
LANGUAGE PLPGSQL
AS $
DECLARE
    result TEXT;
BEGIN
    IF par_wind_speed IS NULL THEN
        RAISE EXCEPTION 'Скорость ветра не может быть NULL';
    END IF;

    IF par_wind_speed BETWEEN 0 AND 5 THEN
        result := 'correction_0_5';
    ELSIF par_wind_speed BETWEEN 6 AND 10 THEN
        result := 'correction_6_10';
    ELSIF par_wind_speed BETWEEN 11 AND 15 THEN
        result := 'correction_11_15';
    ELSIF par_wind_speed BETWEEN 16 AND 20 THEN
        result := 'correction_16_20';
    ELSIF par_wind_speed BETWEEN 21 AND 25 THEN
        result := 'correction_21_25';
    ELSE
        RAISE EXCEPTION 'Скорость ветра % вне допустимого диапазона (0-25 м/с)', par_wind_speed;
    END IF;

    RETURN result;
END;
$;

COMMENT ON FUNCTION public.fn_get_wind_group IS 'Определяет группу скорости ветра для получения соответствующей поправки';

CREATE OR REPLACE FUNCTION public.fn_get_wind_correction(
    par_height INTEGER,
    par_wind_speed NUMERIC(8,2)
)
RETURNS NUMERIC(8,2)
LANGUAGE PLPGSQL
AS $
DECLARE
    nearest_height INTEGER;
    correction_column TEXT;
    result NUMERIC(8,2);
BEGIN
    SELECT height INTO nearest_height
    FROM public.wind_corrections
    ORDER BY ABS(height - par_height) ASC
    LIMIT 1;

    IF nearest_height IS NULL THEN
        RAISE EXCEPTION 'Не найдены данные о ветровых поправках для высоты %', par_height;
    END IF;

    correction_column := public.fn_get_wind_group(par_wind_speed);

    EXECUTE format('SELECT %I FROM public.wind_corrections WHERE height = $1', correction_column)
    INTO result
    USING nearest_height;

    RETURN result;
END;
$;