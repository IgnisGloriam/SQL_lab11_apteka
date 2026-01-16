
-- роль для менеджера (как бы директора аптеки)
CREATE ROLE Role_Manager

-- роль для сотрудника
CREATE ROLE Role_Employee

-- ну менеджер должен быть способен отвечать за свою локальную аптеку, то есть набирать и удалять сотрудников, 
-- а также он может оформлять заказы и производить продажи
GRANT SELECT, INSERT, UPDATE, DELETE ON 
    [dbo].[employee] TO Role_Manager 
GRANT SELECT, INSERT, UPDATE, DELETE ON 
    [dbo].[manufacturer] TO Role_Manager
GRANT SELECT, INSERT, UPDATE, DELETE ON 
    [dbo].[drug] TO Role_Manager
GRANT SELECT, INSERT, UPDATE, DELETE ON 
    [dbo].[section] TO Role_Manager
GRANT SELECT, INSERT, UPDATE, DELETE ON 
    [dbo].[medication] TO Role_Manager
GRANT SELECT, INSERT, UPDATE, DELETE ON 
    [dbo].[active_substance] TO Role_Manager
GRANT SELECT, INSERT, UPDATE, DELETE ON 
    [dbo].[medication_indication] TO Role_Manager
GRANT SELECT, INSERT, UPDATE, DELETE ON 
    [dbo].[medication_substance] TO Role_Manager
GRANT SELECT, INSERT, UPDATE, DELETE ON 
    [dbo].[disease] TO Role_Manager 

GRANT SELECT, INSERT, UPDATE ON 
    [dbo].[sale] TO Role_Manager WITH GRANT OPTION
GRANT SELECT, INSERT, UPDATE ON 
    [dbo].[sale_content] TO Role_Manager WITH GRANT OPTION
GRANT SELECT, INSERT, UPDATE ON 
    [dbo].[client] TO Role_Manager WITH GRANT OPTION
GRANT SELECT, INSERT, UPDATE ON 
    [dbo].[order] TO Role_Manager WITH GRANT OPTION
GRANT SELECT, INSERT, UPDATE ON 
    [dbo].[order_content] TO Role_Manager WITH GRANT OPTION

GRANT SELECT ON [dbo].[manufacturer] TO Role_Manager
GRANT SELECT ON [dbo].[drug] TO Role_Manager
GRANT SELECT ON [dbo].[section] TO Role_Manager
GRANT SELECT ON [dbo].[medication] TO Role_Manager
GRANT SELECT ON [dbo].[active_substance] TO Role_Manager



GRANT EXECUTE ON [dbo].[CalculateAverageDrugsPerSale] TO Role_Manager WITH GRANT OPTION
GRANT EXECUTE ON [dbo].[FindCheapestAnalog] TO Role_Manager WITH GRANT OPTION
GRANT EXECUTE ON [dbo].[GetExpiringMedications] TO Role_Manager WITH GRANT OPTION
GRANT EXECUTE ON [dbo].[GetMedicationsBySubstance] TO Role_Manager WITH GRANT OPTION
GRANT EXECUTE ON [dbo].[GetSalesAboveAverage] TO Role_Manager WITH GRANT OPTION


GRANT EXECUTE ON [dbo].[GetDailyRevenue] TO Role_Manager WITH GRANT OPTION
GRANT SELECT ON [dbo].[GetMedicationsForDisease] TO Role_Manager WITH GRANT OPTION
GRANT SELECT ON [dbo].[GetSoldDrugsByDate] TO Role_Manager WITH GRANT OPTION


----------------------------------------------------------------


GRANT SELECT ON [dbo].[manufacturer] TO Role_Employee
GRANT SELECT, UPDATE(quantity) ON drug TO Role_Employee
GRANT SELECT ON [dbo].[section] TO Role_Employee
GRANT SELECT ON [dbo].[medication] TO Role_Employee
GRANT SELECT ON [dbo].[active_substance] TO Role_Employee


GRANT SELECT, INSERT, UPDATE ON [dbo].[sale] TO Role_Employee
GRANT SELECT, INSERT, UPDATE ON [dbo].[sale_content] TO Role_Employee
GRANT SELECT, INSERT, UPDATE ON [dbo].[order] TO Role_Employee
GRANT SELECT, INSERT, UPDATE ON [dbo].[order_content] TO Role_Employee

GRANT SELECT ON [dbo].[client] TO Role_Employee


GRANT SELECT ON [dbo].[disease] TO Role_Employee
GRANT SELECT ON [dbo].[medication_indication] TO Role_Employee
GRANT SELECT ON [dbo].[medication_substance] TO Role_Employee


GRANT EXECUTE ON [dbo].[CalculateAverageDrugsPerSale] TO Role_Employee
GRANT EXECUTE ON [dbo].[FindCheapestAnalog] TO Role_Employee
GRANT EXECUTE ON [dbo].[GetExpiringMedications] TO Role_Employee
GRANT EXECUTE ON [dbo].[GetMedicationsBySubstance] TO Role_Employee
GRANT EXECUTE ON [dbo].[GetSalesAboveAverage] TO Role_Employee


GRANT EXECUTE ON [dbo].[GetDailyRevenue] TO Role_Employee
GRANT SELECT ON [dbo].[GetMedicationsForDisease] TO Role_Employee
GRANT SELECT ON [dbo].[GetSoldDrugsByDate] TO Role_Employee

-- DENY SELECT ON [dbo].[employee] TO Role_Employee
REVOKE SELECT ON [dbo].[employee] TO Role_Employee

GRANT SELECT ON [dbo].[employee](full_name) TO Role_Employee



 
---------------------------------


SELECT * FROM sys.server_principals 
SELECT * FROM sys.database_principals



CREATE LOGIN manag WITH PASSWORD = '1', 
    CHECK_EXPIRATION = OFF,
    CHECK_POLICY = OFF
CREATE LOGIN emp WITH PASSWORD = '1',
    CHECK_EXPIRATION = OFF,
    CHECK_POLICY = OFF

CREATE USER manag FOR LOGIN manag
CREATE USER emp FOR LOGIN emp

ALTER ROLE Role_Manager ADD MEMBER [manag]
ALTER ROLE Role_Employee ADD MEMBER [emp]

GRANT CONNECT TO manag
GRANT CONNECT TO emp






-----------------------------------------------------


-- Можно EXECUTE AS USER = 'emp'

-- Тестирование под пользователем-руководителем (должно работать):
-- SELECT * FROM dbo.employee -- доступно
-- DELETE FROM employee WHERE id = 1  -- Доступно
-- EXEC dbo.GetSalesAboveAverage -- Процедура доступна
-- SELECT dbo.GetDailyRevenue('2024-01-01') -- Функция доступна

-- Тестирование под пользователем-сотрудником (ограниченный доступ):
-- SELECT * FROM dbo.employee -- ДОЛЖНО ВЫЗВАТЬ ОШИБКУ
-- SELECT * FROM dbo.drug -- Должно работать 
-- EXEC dbo.GetExpiringMedications -- Должно работать 



-- От имени сотрудника (emp) можно выполнить:
/*
-- Просмотр данных
SELECT * FROM medication  -- Доступно

-- Обновление количества
UPDATE drug SET quantity = 50 WHERE id = 1  -- Доступно (только поле quantity)

-- Попытка удаления (будет запрещено)
DELETE FROM sale WHERE id = 1  -- Запрещено

-- Попытка обновления цены (будет запрещено)
UPDATE drug SET price = 100 WHERE id = 1  -- Запрещено (кроме quantity)
*/




------------------------------------------


REVOKE INSERT ON sale FROM Role_Employee
GO

-- Предоставить право на UPDATE для определенных полей employee
GRANT UPDATE(profession) ON employee TO Role_Employee
GO

-- Полный запрет на доступ к таблице client для сотрудника
DENY SELECT ON client TO Role_Employee
GO






---------------------------------------------------------------------------------------------------------

-- 2

ALTER TABLE [dbo].[client]
ALTER COLUMN [address] ADD MASKED WITH (FUNCTION = 'partial(2,"xxxx",0)')

GRANT UNMASK TO Role_Manager

-- SELECT * FROM Client




CREATE OR ALTER VIEW client_masked_view
AS
SELECT id,
    LEFT(full_name, 1) + '****** ' + 
    LEFT(SUBSTRING(full_name, CHARINDEX(' ', full_name) + 1, 100), 1) + '.' +
    LEFT(SUBSTRING(SUBSTRING(full_name, CHARINDEX(' ', full_name) + 1, 100), 
        CHARINDEX(' ', SUBSTRING(full_name, CHARINDEX(' ', full_name) + 1, 100)) + 1, 100), 1) + '.'
    AS masked_full_name,

    LEFT(address, 3) + '******'
    AS masked_address
FROM client
GO


GRANT SELECT ON client_masked_view TO Role_Employee
GRANT SELECT ON client_masked_view TO Role_Manager
-- SELECT * FROM client_masked_view




CREATE OR ALTER PROCEDURE client_masked_pr
AS
BEGIN
    SELECT id,
        LEFT(full_name, 1) + '****** ' + ' ' +
        LEFT(SUBSTRING(full_name, CHARINDEX(' ', full_name) + 1, 100), 1) + '.' +
        LEFT(SUBSTRING(SUBSTRING(full_name, CHARINDEX(' ', full_name) + 1, 100), 
            CHARINDEX(' ', SUBSTRING(full_name, CHARINDEX(' ', full_name) + 1, 100)) + 1, 100), 1) + '.'
        AS masked_full_name,

        LEFT(address, 3) + '******' AS masked_address
    FROM client
END
GO


GRANT EXEC ON client_masked_pr TO Role_Employee
GRANT EXEC ON client_masked_pr TO Role_Manager
-- EXEC client_masked_pr


CREATE OR ALTER FUNCTION address_masked_fn(@id INT)
RETURNS NVARCHAR(200)
AS
BEGIN
    DECLARE @result NVARCHAR(200)
    
    DECLARE @address NVARCHAR(200)
    SELECT @address = address FROM client WHERE id = @id
    
    SET @result = LEFT(@address, 3) + '****' + RIGHT(@address, 3)
    
    RETURN @result
END


GRANT EXEC ON address_masked_fn TO Role_Employee
GRANT EXEC ON address_masked_fn TO Role_Manager
-- SELECT dbo.address_masked_fn(1)








