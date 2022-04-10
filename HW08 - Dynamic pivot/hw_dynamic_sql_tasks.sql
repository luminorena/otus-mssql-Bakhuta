/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/
--etalon pivot

use WideWorldImporters
;with cte as (
select 
DATEADD(month,DATEDIFF(MONTH,0, i.InvoiceDate),0) as InvoiceDate,
i.InvoiceID,
SUBSTRING(CustomerName, 
CHARINDEX('(', CustomerName) + 1, len(CustomerName)- CHARINDEX('(', CustomerName) -1) as ShortName
from Sales.Customers c
join sales.Invoices i on i.CustomerID = c.CustomerID
)
select * from cte
pivot (count(InvoiceId) for ShortName in ([Peeples Valley, AZ],[Medicine Lodge, KS],
[Gasport, NY],[Sylvanite, MT], [Jessie, ND]))
as PivotTable
order by InvoiceDate


go
declare @InvoiceId as INT
declare @ColumnName as NVARCHAR(MAX)
declare @CustomerName as NVARCHAR(MAX)
declare @InvoiceDate as date
select @ColumnName = 
DATEADD(month,DATEDIFF(MONTH,0, @InvoiceDate = i.InvoiceDate),0), @InvoiceId = i.InvoiceID,
SUBSTRING(@CustomerName = CustomerName, CHARINDEX('(', @CustomerName = CustomerName) + 1, 
len(@CustomerName = CustomerName)- CHARINDEX('(',@CustomerName = CustomerName) -1) as ShortName
from Sales.Customers c
join sales.Invoices i on i.CustomerID = c.CustomerID
