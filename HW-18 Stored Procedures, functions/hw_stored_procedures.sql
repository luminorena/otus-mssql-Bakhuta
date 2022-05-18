/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

--Предварительно нужно создать схему
--CREATE SCHEMA [udf] AUTHORIZATION [dbo]

/*
Не знаю, верно ли поняла задание. В функцию передается айди клиента, и по нему уже вычисляется, какая
максимальная сумма его заказа. Если просто делать максимальную стоимость (запрос привела сразу после
функции) и этот запрос запихнуть в функцию, то будет ошибка, что нельзя никакие order by использовать в 
функции, а именно в части оконной функции. Ниже написала второй вариант этой функции.
*/
 
GO  
 
DROP FUNCTION if exists udf.getClientWithMaxPurchase
go
CREATE FUNCTION udf.getClientWithMaxPurchase (@customerid int)
RETURNS TABLE
as 
RETURN
(
select top 1
	sc.CustomerID
	, max(UnitPrice*Quantity) as Maxprice
	from sales.Customers sc 
	join sales.Invoices si on sc.CustomerID = si.CustomerID
	join sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
	where sc.CustomerID = @customerid
	group by UnitPrice*Quantity, sc.CustomerID
	order by Maxprice desc
);

select * from udf.getClientWithMaxPurchase (14)

-- запрос на максимальную стоимость - клиенты, у которых максимальная стоимость

;with cte as
 (
select distinct 
	sc.CustomerID
	, UnitPrice*Quantity as [Sum]
	, max(UnitPrice*Quantity) as Maxprice
	, DENSE_RANK() OVER (ORDER BY UnitPrice*Quantity desc) as [Rank]
	from sales.Customers sc 
	join sales.Invoices si on sc.CustomerID = si.CustomerID
	join sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
	group by UnitPrice*Quantity, sc.CustomerID
)
select CustomerId, MaxPrice, [Sum]
from cte 
where [Rank] = 1
order by Maxprice desc, CustomerID

--Функция для выборки всех maxprice для всех клиентов

drop FUNCTION if exists udf.getMaxPriceForAllClients
CREATE FUNCTION udf.getMaxPriceForAllClients()
RETURNS TABLE  
AS  
RETURN 
(
select top 100 percent
	sc.CustomerID
	, max(UnitPrice*Quantity) as Maxprice
	from sales.Customers sc 
	join sales.Invoices si on sc.CustomerID = si.CustomerID
	join sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
	group by UnitPrice*Quantity, sc.CustomerID
	order by Maxprice desc, CustomerID
);

--тут если запусить запрос отдельно, то выведет нормально, если в функции, то в разнобой, надо order by
-- дописывать

select * from udf.getMaxPriceForAllClients ()
order by MaxPrice desc

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

--CREATE SCHEMA [usp] AUTHORIZATION [dbo]

USE WideWorldImporters;  
GO  
IF OBJECT_ID ( 'usp.GetPurchaseSum', 'P' ) IS NOT NULL   
    DROP PROCEDURE usp.GetPurchaseSum; 
GO
CREATE PROCEDURE usp.GetPurchaseSum    
    @CustomerID int 
AS   

    SET NOCOUNT ON;  
	select UnitPrice*Quantity as [Sum], [Description] 
	from sales.Customers sc 
	join sales.Invoices si on sc.CustomerID = si.CustomerID
	join sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
	where sc.CustomerID = @CustomerID
GO 

exec usp.GetPurchaseSum  @CustomerId=2
/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

/* Задание из домашки про подзапросы
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

--функция
CREATE FUNCTION udf.SalesPeople ()
RETURNS TABLE  
AS  
RETURN 
(
select p.* from [Application].people p
where  IsSalesperson = 1 and not exists (select * from Sales.Invoices i
where i.ContactPersonID = p.PersonID 
and i.InvoiceDate<>'2013-06-04')
);

select * from udf.SalesPeople ()

--процедура

go
IF OBJECT_ID ('usp.SalesPeople_procedure', 'P' ) IS NOT NULL   
    DROP PROCEDURE usp.SalesPeople_procedure;  
GO  
CREATE PROCEDURE usp.SalesPeople_procedure 
AS  
    SET NOCOUNT ON;  
   select p.* from [Application].people p
where  IsSalesperson = 1 and not exists (select * from Sales.Invoices i
where i.ContactPersonID = p.PersonID 
and i.InvoiceDate<>'2013-06-04')  
GO  
 
exec usp.SalesPeople_procedure

--Про производительность - если запустить с планом, то можно увидеть, что он одинаковый.

select * from udf.SalesPeople()
exec usp.SalesPeople_procedure

-- но теперь надо сравнить время выполнения процедуры и функции

SET STATISTICS io ON
SET STATISTICS time ON
-- предварительно очищаем буфер
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
SET NOCOUNT ON
--запускаем
select * from udf.SalesPeople()
exec usp.SalesPeople_procedure

-- в результате мы видим, что функция отрабатывает быстрее. 
-- Как понимаю, табличные функции всегда быстрее работают ? Или зависит от каких-то параметров всё же?

/*
 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 141 ms.

 SQL Server Execution Times:
   CPU time = 15 ms,  elapsed time = 181 ms.
*/

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки 
result set'а без использования цикла. 
*/

USE [tempdb] 
GO
 
IF EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'[Employee]') AND type IN (N'U')) 
BEGIN 
   DROP TABLE [Employee] 
END 
GO 

IF EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'[Department]') AND type IN (N'U')) 
BEGIN 
   DROP TABLE [Department] 
END 

CREATE TABLE [Department]( 
   [DepartmentID] [int] NOT NULL PRIMARY KEY, 
   [Name] VARCHAR(250) NOT NULL, 
) ON [PRIMARY] 

INSERT [Department] ([DepartmentID], [Name])  
VALUES (1, N'Engineering') 
INSERT [Department] ([DepartmentID], [Name])  
VALUES (2, N'Administration') 
INSERT [Department] ([DepartmentID], [Name])  
VALUES (3, N'Sales') 
INSERT [Department] ([DepartmentID], [Name])  
VALUES (4, N'Marketing') 
INSERT [Department] ([DepartmentID], [Name])  
VALUES (5, N'Finance') 
GO 

CREATE TABLE [Employee]( 
   [EmployeeID] [int] NOT NULL PRIMARY KEY, 
   [FirstName] VARCHAR(250) NOT NULL, 
   [LastName] VARCHAR(250) NOT NULL, 
   [DepartmentID] [int] NOT NULL REFERENCES [Department](DepartmentID), 
) ON [PRIMARY] 
GO
 
INSERT [Employee] ([EmployeeID], [FirstName], [LastName], [DepartmentID]) 
VALUES (1, N'Иван', N'Иванов', 1 ) 
INSERT [Employee] ([EmployeeID], [FirstName], [LastName], [DepartmentID]) 
VALUES (2, N'Ольга', N'Петрова', 2 ) 
INSERT [Employee] ([EmployeeID], [FirstName], [LastName], [DepartmentID]) 
VALUES (3, N'Екатерина', N'Сидорова', 3 ) 
INSERT [Employee] ([EmployeeID], [FirstName], [LastName], [DepartmentID]) 
VALUES (4, N'Алексей', N'Николаев', 3 ) 

--Не понимаю ,почему получается ошибка. Курсором, как понимаю, нельзя же? 
--Column names in each view or function must be unique. 
--Column name 'DepartmentID' in view or function 'TestFunction' is specified more than once.

CREATE FUNCTION ufn.TestFunction ()  
RETURNS TABLE  
AS  
RETURN  
(
SELECT * FROM Department D 
CROSS APPLY 
   ( 
   SELECT * FROM Employee E 
   WHERE E.DepartmentID = D.DepartmentID 
   ) a
);

/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/

-- добавлю после исправления п.4
