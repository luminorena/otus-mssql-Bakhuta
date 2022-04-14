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

go
DECLARE @dml AS NVARCHAR(MAX)
DECLARE @CustomerName nvarchar(MAX)
SELECT @CustomerName = ISNULL(@CustomerName + ',', '') + QUOTENAME([CustomerName])
FROM [Sales].[Customers]
ORDER BY [CustomerName]
set @dml = N'select DATEADD(month,DATEDIFF(MONTH,0, InvoiceDate),0) as InvoiceDate, 
' +@CustomerName + ' FROM
(
select 
DATEADD(month,DATEDIFF(MONTH,0, i.InvoiceDate),0) as InvoiceDate,
i.InvoiceID,
CustomerName
from Sales.Customers c
join sales.Invoices i on i.CustomerID = c.CustomerID
--order by InvoiceDate
) as a
PIVOT (count(InvoiceId) FOR CustomerName in (' + @CustomerName + ')) as PivotTable
order by InvoiceDate'
EXEC sp_executesql @dml


