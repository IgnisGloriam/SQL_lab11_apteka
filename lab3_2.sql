-- a) Найти всех производителей, 
-- чьи лекарства имеются на данный момент в аптеке
SELECT DISTINCT m.name manufacturer_name
FROM manufacturer m
JOIN drug d ON m.id = d.manufacturer_id
WHERE d.quantity > 0
ORDER BY m.name

-- b) Вывести заболевания, для которых в аптеке нет лекарств
SELECT 
    d.name disease_name
FROM disease d
WHERE d.id NOT IN (
    SELECT DISTINCT mi.disease_id
    FROM medication_indication mi
    JOIN drug dr ON mi.medication_id = dr.medication_id
    WHERE dr.quantity > 0
)


SELECT mi.disease_id, dr.*
FROM medication_indication mi
JOIN drug dr ON mi.medication_id = dr.medication_id
WHERE dr.quantity > 0

-- c) Найти самые дешевые лекарства с основным 
-- действующим веществом «дротаверин» (зато есть парацетамол)

-- через CTE и из двух как минимум элементов
WITH min_price AS (
    SELECT MIN(d.price) min_price
    FROM drug d
    JOIN medication_substance ms 
        ON d.medication_id = ms.medication_id
    JOIN active_substance a ON ms.active_substance_id = a.id
    WHERE LOWER(a.name) = 'парацетамол'
        AND d.quantity > 0
)
SELECT 
    med.name medication_name,
    d.price,
    d.quantity,
    m.name manufacturer_name
FROM medication med
JOIN medication_substance ms ON med.id = ms.medication_id
JOIN active_substance a ON ms.active_substance_id = a.id
JOIN drug d ON med.id = d.medication_id
JOIN manufacturer m ON d.manufacturer_id = m.id
WHERE LOWER(a.name) = 'парацетамол'
    AND d.price = (SELECT min_price FROM min_price)
    AND d.quantity > 0




SELECT 
    med.name medication_name,
    d.price,
    d.quantity,
    m.name manufacturer_name
FROM medication med
JOIN medication_substance ms ON med.id = ms.medication_id
JOIN active_substance a ON ms.active_substance_id = a.id
JOIN drug d ON med.id = d.medication_id
JOIN manufacturer m ON d.manufacturer_id = m.id
WHERE LOWER(a.name) = 'парацетамол'
    AND d.price = (
        SELECT MIN(d2.price)
        FROM drug d2
        JOIN medication_substance ms2 
            ON d2.medication_id = ms2.medication_id
        JOIN active_substance a2 ON ms2.active_substance_id = a2.id
        WHERE LOWER(a2.name) = 'парацетамол'
    )
    AND d.quantity > 0

-- d) Найти все лекарства от ангины И насморка
WITH m_to_d1 AS (
    SELECT m.medication_id m_id
    FROM medication_indication m
    JOIN disease d ON m.disease_id = d.id 
    WHERE LOWER(d.name) = 'ангина'
), m_to_d2 AS (
    SELECT m.medication_id m_id
    FROM medication_indication m
    JOIN disease d ON m.disease_id = d.id 
    WHERE LOWER(d.name) = 'грипп'
)
SELECT DISTINCT
    med.name medication_name,
    --d.name disease_name,
    dr.quantity,
    dr.price
FROM medication med
JOIN medication_indication mi ON med.id = mi.medication_id
JOIN disease d ON mi.disease_id = d.id
JOIN drug dr ON med.id = dr.medication_id
WHERE LOWER(med.id) IN (SELECT m_id FROM m_to_d1)
    AND LOWER(med.id) IN (SELECT m_id FROM m_to_d2)
    AND dr.quantity > 0
ORDER BY med.name --d.name, med.name









SELECT
    med.name medication_name,
    d.name disease_name,
    dr.quantity,
    dr.price
FROM medication med
JOIN medication_indication mi ON med.id = mi.medication_id
JOIN disease d ON mi.disease_id = d.id
JOIN drug dr ON med.id = dr.medication_id
WHERE LOWER(d.name) IN ('ангина', 'грипп')
    AND dr.quantity > 0
ORDER BY d.name, med.name




-- e) Для КАЖДОГО (0) лекарства вывести количество 
-- проданных с начала года упаковок с упорядочением 
-- кол-ва упаковок по убыванию
SELECT 
    med.name medication_name,
    ISNULL(SUM(CASE 
        WHEN YEAR(s.sale_date) = YEAR(GETDATE()) THEN sc.quantity 
        ELSE 0 
    END), 0) total_sold_quantity
FROM medication med
LEFT JOIN drug d ON med.id = d.medication_id
LEFT JOIN sale_content sc ON d.id = sc.drug_id 
LEFT JOIN sale s ON sc.sale_id = s.id 
-- WHERE YEAR(s.sale_date) = YEAR(GETDATE()) 
GROUP BY med.id, med.name
ORDER BY total_sold_quantity DESC


SELECT 
    med.name medication_name,
    SUM(sc.quantity) total_sold_quantity
FROM medication med
LEFT JOIN drug d ON med.id = d.medication_id
LEFT JOIN sale_content sc ON d.id = sc.drug_id
LEFT JOIN sale s ON sc.sale_id = s.id
AND YEAR(s.sale_date) = YEAR(GETDATE()) 
GROUP BY med.id, med.name
ORDER BY total_sold_quantity DESC

-- f) Выдать выручку аптеки за вчерашний день 
-- по каждому разделу лекарств

-- сделать в базе вчерашние заказы
SELECT 
    s.name section_name,
    ISNULL(SUM(sa.total_amount), 0) daily_revenue
FROM section s
LEFT JOIN medication m ON s.id = m.section_id
LEFT JOIN drug d ON m.id = d.medication_id
LEFT JOIN sale_content sc ON d.id = sc.drug_id
LEFT JOIN sale sa ON sc.sale_id = sa.id 
AND sa.sale_date = CAST(GETDATE() - 1 AS DATE)
GROUP BY s.id, s.name
ORDER BY SUM(sa.total_amount) DESC







--SELECT 
--    s.name section_name,
--    SUM(sa.total_amount) daily_revenue
--FROM section s
--JOIN medication m ON s.id = m.section_id
--JOIN drug d ON m.id = d.medication_id
--JOIN sale_content sc ON d.id = sc.drug_id
--JOIN sale sa ON sc.sale_id = sa.id
--WHERE sa.sale_date = CAST(GETDATE() - 1 AS DATE)  -- вчерашний день
--GROUP BY s.id, s.name
--ORDER BY daily_revenue DESC

-- Или явно продемонстрируем отсутствие продаж вчера:
--SELECT 
--    s.name section_name,
--    ISNULL(SUM(sa.total_amount), 0) daily_revenue
--FROM section s
--LEFT JOIN medication m ON s.id = m.section_id
--LEFT JOIN drug d ON m.id = d.medication_id
--LEFT JOIN sale_content sc ON d.id = sc.drug_id
--LEFT JOIN sale sa ON sc.sale_id = sa.id 
--AND sa.sale_date = CAST(GETDATE() - 1 AS DATE)
--GROUP BY s.id, s.name
--ORDER BY SUM(sa.total_amount) DESC
