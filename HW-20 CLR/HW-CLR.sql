-- Включаем CLR
exec sp_configure 'show advanced options', 1;
GO
reconfigure;
GO

exec sp_configure 'clr enabled', 1;
exec sp_configure 'clr strict security', 0 
GO
reconfigure;
GO

-- Для возможности создания сборок с EXTERNAL_ACCESS или UNSAFE
ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON; 

-- Подключаем dll 
CREATE ASSEMBLY IpAddressAssembly
FROM 'C:\Users\olech\source\repos\IpAddresses\bin\Debug\IpAddresses.dll'
WITH PERMISSION_SET = SAFE;  

-- Посмотреть подключенные сборки (SSMS: <DB> -> Programmability -> Assemblies)
SELECT * FROM sys.assemblies

-- Подключить функцию из dll - AS EXTERNAL NAME
--сборка, namespace, class, method
CREATE FUNCTION dbo.IpAddresses(@inputString nvarchar(100))  
RETURNS nvarchar(100)
AS EXTERNAL NAME [IpAddressAssembly].[IpAddresses.Class1].ClrFunction;
GO 

-- Используем функцию
SELECT dbo.IpAddresses('192.168.0.1')


-- --------------------------

-- Список подключенных CLR-объектов
SELECT * FROM sys.assembly_modules
