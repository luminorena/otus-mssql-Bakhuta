-- �������� CLR
exec sp_configure 'show advanced options', 1;
GO
reconfigure;
GO

exec sp_configure 'clr enabled', 1;
exec sp_configure 'clr strict security', 0 
GO
reconfigure;
GO

-- ��� ����������� �������� ������ � EXTERNAL_ACCESS ��� UNSAFE
ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON; 

-- ���������� dll 
CREATE ASSEMBLY IpAddressAssembly
FROM 'C:\Users\olech\source\repos\IpAddresses\bin\Debug\IpAddresses.dll'
WITH PERMISSION_SET = SAFE;  

-- ���������� ������������ ������ (SSMS: <DB> -> Programmability -> Assemblies)
SELECT * FROM sys.assemblies

-- ���������� ������� �� dll - AS EXTERNAL NAME
--������, namespace, class, method
CREATE FUNCTION dbo.IpAddresses(@inputString nvarchar(100))  
RETURNS nvarchar(100)
AS EXTERNAL NAME [IpAddressAssembly].[IpAddresses.Class1].ClrFunction;
GO 

-- ���������� �������
SELECT dbo.IpAddresses('192.168.0.1')


-- --------------------------

-- ������ ������������ CLR-��������
SELECT * FROM sys.assembly_modules
