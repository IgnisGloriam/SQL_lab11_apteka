-- a) Найти всех производителей, 
-- чьи лекарства имеются на данный момент в аптеке
SELECT DISTINCT 
    m.name manufacturer_name
FROM manufacturer_node m, 
     drug_node d, 
     manufactured_by_edge e
WHERE MATCH(d-(e)->m)
    AND d.quantity > 0
ORDER BY m.name




-- b) Вывести заболевания, для которых в аптеке нет лекарств
SELECT 
    d.name disease_name
FROM disease_node d
WHERE NOT EXISTS (
    SELECT 1
    FROM medication_node m, 
         drug_node dr, 
         has_indication_edge hi, 
         belongs_to_edge bt
    WHERE MATCH(m-(hi)->d AND dr-(bt)->m)
        AND dr.quantity > 0
)
ORDER BY d.name


-- c) Найти самые дешевые лекарства с основным 
-- действующим веществом «дротаверин» (зато есть парацетамол)

-- через CTE и из двух как минимум элементов
-- Графовое решение
WITH min_price AS (
    SELECT MIN(d.price) min_price
    FROM active_substance_node a, 
         medication_node med, 
         drug_node d, 
         contains_substance_edge cs, 
         belongs_to_edge bt
    WHERE MATCH(med-(cs)->a AND d-(bt)->med)
        AND LOWER(a.name) = 'парацетамол'
        AND d.quantity > 0
)
SELECT 
    med.name medication_name,
    d.price,
    d.quantity,
    m.name manufacturer_name,
    d.expiration_date
FROM active_substance_node a, 
     medication_node med, 
     drug_node d, 
     manufacturer_node m,
     contains_substance_edge cs, 
     belongs_to_edge bt,
     manufactured_by_edge mb
WHERE MATCH(med-(cs)->a AND d-(bt)->med AND d-(mb)->m)
    AND LOWER(a.name) = 'парацетамол'
    AND d.price = (SELECT min_price FROM min_price)
    AND d.quantity > 0



-- d) Найти все лекарства от ангины и насморка


SELECT
    med.name medication_name,
    d.name disease_name,
    dr.quantity,
    dr.price
FROM drug_node dr,
     medication_node med,
     disease_node d,
     belongs_to_edge bt,
     has_indication_edge hi
WHERE MATCH(dr-(bt)->med-(hi)->d)
    AND LOWER(d.name) IN ('ангина', 'грипп')
    AND dr.quantity > 0
ORDER BY d.name, med.name




-- e) Для КАЖДОГО (0) лекарства вывести количество 
-- проданных с начала года упаковок с упорядочением 
-- кол-ва упаковок по убыванию
SELECT 
    med.name medication_name,
    ISNULL((
        SELECT SUM(ide.quantity)
        FROM drug_node d, 
             sale_node s, 
             includes_drug_edge ide, 
             belongs_to_edge bt
        WHERE MATCH(s-(ide)->d-(bt)->med)
            AND YEAR(s.sale_date) = YEAR(GETDATE())
    ), 0) total_sold_quantity
FROM medication_node med
ORDER BY total_sold_quantity DESC


-- f) Выдать выручку аптеки за вчерашний день 
-- по каждому разделу лекарств

SELECT 
    s.name section_name,
    ISNULL((
        SELECT SUM(sa.total_amount)
        FROM medication_node m,
             drug_node d,
             sale_node sa,
             in_section_edge ise,
             belongs_to_edge bt,
             includes_drug_edge ide
        WHERE MATCH(sa-(ide)->d-(bt)->m-(ise)->s)
        AND sa.sale_date = '2023-10-02'
    ), 0) daily_revenue
FROM section_node s
ORDER BY daily_revenue DESC







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
