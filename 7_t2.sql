-- Проверка потерянных изменений

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRANSACTION
SELECT quantity FROM drug WHERE id = 1
-- Ждем...
UPDATE drug SET quantity = 10 WHERE id = 1
COMMIT
SELECT quantity FROM drug WHERE id = 1









-- Проверка грязного чтения
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRANSACTION
-- Отобразим список цен на сайте
SELECT price FROM drug WHERE id = 2
COMMIT
SELECT price FROM drug WHERE id = 2






-- ROLLBACK

-- Проверка грязного чтения 2
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
-- Отобразим список цен на сайте
SELECT price FROM drug WHERE id = 2
COMMIT
SELECT price FROM drug WHERE id = 2










-- Проверка неповторяющегося чтения
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
UPDATE drug SET price = price * 1.2 WHERE id = 4 -- Изменяем данные между чтениями T1
COMMIT









-- Проверка неповторяющегося чтения 2
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRANSACTION
UPDATE drug SET quantity = quantity - 2 WHERE id = 5 -- блокируется
COMMIT


SELECT quantity FROM drug WHERE id = 5








-- Проверка фантомов
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRANSACTION
INSERT INTO drug (quantity, price, expiration_date, medication_id, manufacturer_id)
VALUES (50, 75.00, '2025-12-31', 1, 1)
COMMIT








-- Проверка фантомов 2
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
BEGIN TRANSACTION
INSERT INTO drug (quantity, price, expiration_date, medication_id, manufacturer_id)
VALUES (50, 75.00, '2025-12-31', 1, 1)
COMMIT







