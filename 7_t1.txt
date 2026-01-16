-- Проверка потерянных изменений

-- UPDATE drug SET quantity = 100 WHERE id = 1
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRANSACTION
SELECT quantity FROM drug WHERE id = 1
-- Ждем...
UPDATE drug SET quantity = 100 WHERE id = 1
COMMIT
SELECT quantity FROM drug WHERE id = 1


-- в каждой транзакции взяли данные лекарства 1
-- записали ему количество 100 в t1, 
-- записали ему количество 10 в t2, 
-- потеряли quantity = 100 




-- Проверка грязного чтения
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRANSACTION
UPDATE drug SET price = price * 1.1 WHERE id = 2
-- Ждем...
ROLLBACK


SELECT price FROM drug WHERE id = 2


-- цена лекарства 2 была повышена
-- пользователь зашёл на сайт и увидел цену
-- эта цена не была утверждена, транзакция отменилась
-- у пользователя на странице неверная цена, в базе данных цена не изменилась








-- Проверка грязного чтения 2
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
UPDATE drug SET price = price * 1.1 WHERE id = 2
-- Ждем...
ROLLBACK


SELECT price FROM drug WHERE id = 2

-- цена лекарства 2 была повышена
-- пользователь зашёл на сайт и запросил цену
-- эта цена не была утверждена, транзакция отменилась
-- у пользователя на странице верная цена, и в базе данных цена не изменилась








-- Проверка неповторяющегося чтения
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
SELECT price FROM drug WHERE id = 4 -- Первое чтение
-- Ждем...
SELECT price FROM drug WHERE id = 4 -- Второе чтение (может быть другое значение)
COMMIT


-- первое считывание даёт одну цену
-- паралллельная транзакция меняет цену
-- внутри первой транзакции цена меняется без явного изменения








-- Проверка неповторяющегося чтения 2
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRANSACTION
SELECT quantity FROM drug WHERE id = 5
-- Ждем...
SELECT quantity FROM drug WHERE id = 5-- (должно быть то же значение)
COMMIT


-- первое считывание даёт одну цену
-- паралллельная транзакция блокируется
-- внутри первой транзакции цена остаётся та же
-- после 1ой транзакции выполняется 2ая











-- Проверка фантомов
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRANSACTION
SELECT COUNT(*) FROM drug WHERE price BETWEEN 50 AND 100
-- Ждем...
SELECT COUNT(*) FROM drug WHERE price BETWEEN 50 AND 100 -- другой результат
COMMIT


-- первая транзакция смотрит на одно значение COUNT
-- вторая транзакция добавляет ещё одно значениие COUNT
-- внутри первой транзакци COUNT непреднамернно увеличивается






-- Проверка фантомов 2
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
BEGIN TRANSACTION
SELECT COUNT(*) FROM drug WHERE price BETWEEN 50 AND 100
-- Ждем...
SELECT COUNT(*) FROM drug WHERE price BETWEEN 50 AND 100
COMMIT













