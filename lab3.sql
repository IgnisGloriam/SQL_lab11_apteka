-- 1. ВЫБОРКА ИЗ ОДНОЙ ТАБЛИЦЫ

-- 1.1
SELECT id, price, expiration_date 
FROM drug 
ORDER BY price ASC, expiration_date DESC

-- 1.2 
-- Запрос 1
SELECT id, price 
FROM drug 
WHERE price < 100 AND quantity > 50

-- Запрос 2
SELECT id, expiration_date 
FROM drug 
WHERE expiration_date BETWEEN '2024-01-01' AND '2024-12-31'

-- Запрос 3
SELECT id, quantity 
FROM drug 
WHERE quantity BETWEEN 10 AND 100

-- 1.3
-- Без группировки
SELECT 
    COUNT(*) as total_drugs,
    MAX(price) as max_price,
    MIN(price) as min_price,
    AVG(price) as avg_price
FROM drug

-- С группировкой
SELECT 
    manufacturer_id,
    COUNT(*) drugs_count,
    SUM(quantity) total_quantity,
    AVG(price) avg_price
FROM drug 
GROUP BY manufacturer_id

-- 1.4
-- GROUP BY ALL
SELECT 
    manufacturer_id,
    COUNT(*) drug_count,
    ISNULL(AVG(price), 0) avg_price
FROM drug
WHERE price > 100
GROUP BY ALL manufacturer_id

-- ROLLUP
SELECT 
    ISNULL(CAST(manufacturer_id AS VARCHAR), 'TOTAL') manufacturer_id,
    ISNULL(CAST(medication_id AS VARCHAR), 'TOTAL') medication_id,
    SUM(quantity) total_quantity
FROM drug 
GROUP BY ROLLUP(manufacturer_id, medication_id)

-- CUBE
SELECT 
    ISNULL(CAST(manufacturer_id AS VARCHAR), 'TOTAL') manufacturer_id,
    ISNULL(CAST(medication_id AS VARCHAR), 'TOTAL') medication_id,
    COUNT(*) drugs_count,
    AVG(price) avg_price
FROM drug 
GROUP BY CUBE(manufacturer_id, medication_id)

-- 1.5
SELECT name 
FROM medication 
WHERE name NOT LIKE '_е%ин%'

-- 2. ВЫБОРКА ИЗ НЕСКОЛЬКИХ ТАБЛИЦ

-- 2.1 
SELECT e.full_name, s.sale_date
FROM sale s, employee e
WHERE s.employee_id = e.id

SELECT 
    m.name medication_name,
    s.name section_name,
    d.quantity,
    d.price
FROM medication m, section s, drug d
WHERE m.section_id = s.id 
    AND d.medication_id = m.id 
    AND d.price > 50

SELECT 
    m.name medication_name,
    man.name manufacturer_name,
    d.expiration_date
FROM medication m, manufacturer man, drug d
WHERE d.manufacturer_id = man.id 
    AND d.medication_id = m.id 
    AND d.quantity > 0

-- 2.2
SELECT
    e.full_name, 
    s.sale_date
FROM sale s join employee e on s.employee_id = e.id

SELECT 
    m.name medication_name,
    s.name section_name,
    d.quantity,
    d.price
FROM medication m
INNER JOIN section s ON m.section_id = s.id
INNER JOIN drug d ON d.medication_id = m.id
WHERE d.price > 50

SELECT 
    m.name medication_name,
    man.name manufacturer_name,
    d.expiration_date
FROM drug d
INNER JOIN medication m ON d.medication_id = m.id
INNER JOIN manufacturer man ON d.manufacturer_id = man.id
WHERE d.quantity > 0

-- 2.3 
SELECT 
    d.name,
    ISNULL(m.name, 'Лекарства нет') name
FROM disease d LEFT JOIN medication_indication m_i ON d.id = m_i.disease_id
    LEFT JOIN medication m ON m_i.medication_id = m.id

SELECT 
    m.name medication_name,
    s.name section_name,
    ISNULL(d.quantity, 0) quantity
FROM medication m
LEFT JOIN section s ON m.section_id = s.id
LEFT JOIN drug d ON d.medication_id = m.id

SELECT 
    man.name manufacturer_name,
    ISNULL(m.name, 'Не производит') drug_name
FROM manufacturer man
LEFT JOIN drug d ON man.id = d.manufacturer_id 
LEFT JOIN medication m ON d.medication_id = m.id

-- 2.4
SELECT 
    ISNULL(d.name, 'Отсутствует') name,
    m.name
FROM disease d RIGHT JOIN medication_indication m_i on d.id = m_i.disease_id
    RIGHT JOIN medication m on m_i.medication_id = m.id


--SELECT 
--    m.name medication_name,
--    d.quantity
--FROM medication m
--RIGHT JOIN drug d ON m.id = d.medication_id

SELECT 
    c.full_name client_name,
    ISNULL(o.total_amount, 0) amount
FROM [order] o
RIGHT JOIN client c ON c.id = o.client_id


-- 2.5
SELECT 
    ISNULL(man.name, 'TOTAL') manufacturer,
    ISNULL(m.name, 'TOTAL') medication,
    COUNT(d.id) drugs_count,
    ISNULL(AVG(price), 0) avg_price
FROM drug d JOIN medication m ON d.medication_id = m.id 
    JOIN manufacturer man ON d.manufacturer_id = man.id
GROUP BY ROLLUP(man.name, m.name)


SELECT 
    man.name manufacturer_name,
    COUNT(d.id) drugs_count,
    ISNULL(SUM(d.quantity), 0) total_quantity,
    ISNULL(AVG(d.price), 0) avg_price
FROM manufacturer man
LEFT JOIN drug d ON man.id = d.manufacturer_id
GROUP BY man.name

SELECT 
    s.name section_name,
    COUNT(m.id) medications_count
FROM section s
LEFT JOIN medication m ON s.id = m.section_id
GROUP BY s.name

-- 2.6
SELECT 
    man.name,
    COUNT(*) drugs_count,
    AVG(price) avg_price
FROM drug d JOIN manufacturer man ON d.manufacturer_id = man.id
GROUP BY d.manufacturer_id, man.name 
HAVING AVG(price) < 210 AND COUNT(*) < 5

SELECT 
    m.section_id,
    s.name section_name,
    COUNT(*) medications_count
FROM medication m
RIGHT JOIN section s ON m.section_id = s.id
GROUP BY m.section_id, s.name
HAVING COUNT(*) < 5


SELECT 
    c.full_name client_name,
    ISNULL(SUM(o.total_amount), 0) all_orders_price
FROM client c
LEFT JOIN [order] o ON c.id = o.client_id
GROUP BY c.id, c.full_name
HAVING COUNT(*) < 10

-- 2.7 
-- IN
SELECT name, price 
FROM drug d JOIN medication m ON d.medication_id = m.id
WHERE manufacturer_id IN (
    SELECT id 
    FROM manufacturer 
    WHERE name LIKE '%Фарм%'
)

-- EXISTS
SELECT name, annotation
FROM medication m
WHERE EXISTS (
    SELECT 1 
    FROM drug d 
    WHERE d.medication_id = m.id AND d.quantity > 100
)


SELECT 
    full_name,
    [address]
FROM client
WHERE id IN (
    SELECT client_id
    FROM [order]
    WHERE total_amount > (
        SELECT AVG(total_amount) 
        FROM [order]
    )
)

-- 3. ПРЕДСТАВЛЕНИЯ

-- 3.1 
CREATE VIEW v_manufacturer_drugs_stats AS
SELECT 
    man.name manufacturer_name,
    COUNT(d.id) drugs_count,
    SUM(d.quantity) total_quantity,
    AVG(d.price) avg_price
FROM manufacturer man
JOIN drug d ON man.id = d.manufacturer_id
GROUP BY man.name


CREATE VIEW v_drugs_in_sections AS
SELECT 
    s.name section_name,
    COUNT(m.id) medications_count
FROM section s
LEFT JOIN medication m ON s.id = m.section_id
GROUP BY s.name


-- 3.2 
WITH ManufacturerStats AS (
    SELECT 
        manufacturer_id,
        COUNT(*) drugs_count,
        AVG(price) avg_price
    FROM drug
    GROUP BY manufacturer_id
)
SELECT 
    m.name manufacturer_name,
    ISNULL(ms.drugs_count, 0) drugs_count,
    ISNULL(ms.avg_price, 0) avg_price
FROM ManufacturerStats ms
RIGHT JOIN manufacturer m ON ms.manufacturer_id = m.id
WHERE ms.drugs_count < 5 OR ms.drugs_count IS NULL

WITH LastSales AS (
    SELECT 
        sale_date,
        total_amount,
        employee_id
    FROM sale
    WHERE sale_date >= '2023-01-01'
)
SELECT 
    ls.sale_date,
    ls.total_amount,
    e.full_name employee_name
FROM LastSales ls
JOIN employee e ON ls.employee_id = e.id

-- 4. ФУНКЦИИ РАНЖИРОВАНИЯ

-- 4.1
-- Без PARTITION BY
SELECT 
    name,
    price,
    ROW_NUMBER() OVER (ORDER BY price DESC) [priority]
FROM drug d JOIN medication m ON d.medication_id = m.id

-- (PARTITION BY - для каждого manufacturer_id отдельно)
-- С PARTITION BY
SELECT 
    manufacturer_id,
    name,
    price,
    DENSE_RANK() OVER (PARTITION BY manufacturer_id ORDER BY price) dense_order
FROM drug d JOIN medication m ON d.medication_id = m.id


SELECT 
    section_id,
    name,
    RANK() OVER (PARTITION BY section_id ORDER BY name) [order]
FROM medication

-- 5. ОБЪЕДИНЕНИЕ, ПЕРЕСЕЧЕНИЕ, РАЗНОСТЬ

-- UNION
SELECT name FROM medication
WHERE section_id IN (1, 2)
UNION
SELECT name FROM medication 
WHERE name LIKE '%дин%'

-- UNION ALL
SELECT name, price 
FROM drug d JOIN medication m ON d.medication_id = m.id 
WHERE price > 100
UNION ALL
SELECT name, price 
FROM drug d JOIN medication m ON d.medication_id = m.id 
WHERE quantity > 50
ORDER BY price DESC

-- EXCEPT
SELECT name FROM medication
EXCEPT
SELECT m.name 
FROM medication m
JOIN drug d ON m.id = d.medication_id 
WHERE d.quantity < 50

-- INTERSECT 
SELECT name FROM medication
WHERE section_id = 1
INTERSECT
SELECT m.name 
FROM medication m
JOIN drug d ON m.id = d.medication_id 
WHERE d.price > 50
ORDER BY name

-- 6. CASE, PIVOT и UNPIVOT

-- 6.1 

SELECT 
    m.name,
    d.price,
    CASE WHEN d.price < 50 THEN 'бюджетные' ELSE 'дорогие' END category
FROM drug d JOIN medication m ON d.medication_id = m.id



SELECT
    s.name,
    COUNT(*) total_medications,
    SUM(CASE WHEN LEN(annotation) > 100 THEN 1 ELSE 0 END) long_annotations,
    SUM(CASE WHEN LEN(annotation) <= 100 THEN 1 ELSE 0 END) short_annotations
FROM medication m JOIN section s ON m.section_id = s.id
GROUP BY s.id, s.name

-- 6.2 PIVOT и UNPIVOT
-- PIVOT

-- (у какого товара в эту дату выйдет срок годности на какую сумму)
CREATE VIEW pivot_table AS
SELECT id, 
    ISNULL([2024-06-30], 0) [2024-06-30], 
    ISNULL([2024-09-15], 0) [2024-09-15]
FROM (
    SELECT id, expiration_date, price
    FROM drug
) Sourse
PIVOT (
    SUM(price)
    FOR expiration_date IN ([2024-06-30], [2024-09-15])
) p


-- UNPIVOT
SELECT id, expiration_date, price
FROM pivot_table pt
UNPIVOT (
    price FOR expiration_date IN ([2024-06-30], [2024-09-15])
) up

--SELECT *
--FROM (
--    SELECT 
--        medication_id,
--        price_category = CASE 
--            WHEN price < 50 THEN 'Дешевые'
--            WHEN price BETWEEN 50 AND 200 THEN 'Средние'
--            ELSE 'Дорогие'
--        END,
--        quantity
--    FROM drug
--) AS SourceTable
--PIVOT (
--    SUM(quantity)
--    FOR price_category IN ([Дешевые], [Средние], [Дорогие])
--) AS PivotTable








-- UNPIVOT


--CREATE TABLE #SalesSummary (
--    ManufacturerName VARCHAR(100),
--    Q1_Sales DECIMAL(10,2),
--    Q2_Sales DECIMAL(10,2),
--    Q3_Sales DECIMAL(10,2),
--    Q4_Sales DECIMAL(10,2)
--)

--INSERT INTO #SalesSummary VALUES 
--('Pharma A', 1000, 1200, 900, 1500),
--('Pharma B', 800, 950, 1100, 1300)

--SELECT ManufacturerName, Quarter, Sales
--FROM #SalesSummary
--UNPIVOT (
--    Sales FOR Quarter IN (Q1_Sales, Q2_Sales, Q3_Sales, Q4_Sales)
--) AS UnpivotTable

--DROP TABLE #SalesSummary