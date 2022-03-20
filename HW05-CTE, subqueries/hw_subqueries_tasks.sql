/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

-- вложенный запрос

select p.* from [Application].people p
where not exists (select * from Sales.Invoices i
where i.ContactPersonID = p.PersonID and IsSalesperson = 1
and i.InvoiceDate<>'2013-06-04')


/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

--1 вариант подзапроса

select StockItemID, StockItemName, UnitPrice
from Warehouse.StockItems
where unitprice in (select min(UnitPrice) from Warehouse.StockItems)

--2 вариант подзапроса

select StockItemID, StockItemName, UnitPrice
from Warehouse.StockItems
where unitprice = Any (select min(UnitPrice) from Warehouse.StockItems)

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

/*
если нужны разные клиенты, то можно через оконную функцию выводить, 
если одинаковые могут повторяться в результирующем наборе, то делается
через одну CTE, order by TransactionAmount desc, top 5)
*/

;with preselectData as
(
select CustomerName, TransactionAmount from sales.CustomerTransactions ct
join sales.Customers c on ct.CustomerID = c.CustomerID
),
preselect as 
(
select CustomerName, TransactionAmount, 
DENSE_RANK() over (order by TransactionAmount desc) as denserank
from preselectData
group by CustomerName, TransactionAmount
) 
select CustomerName, TransactionAmount from preselect
where denserank in(1,2,3,5,11)

-- через подзапрос не получится добиться того же условия, что выше с оконной функцией
select distinct top 5 CustomerName, TransactionAmount
from sales.CustomerTransactions ct
join sales.Customers c on ct.CustomerID = c.CustomerID
where CustomerName in (select distinct top 5 CustomerName from sales.CustomerTransactions)
order by TransactionAmount desc


/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

--а тут не могу понять, какие таблицы надо использовать, [Application].Cities
--не могу никак связать с товарами.

select * from sales.Invoices
select * from Warehouse.StockItems
select * from sales.Orders
select * from [Application].Cities
select * from [Application].StateProvinces
select * from [Application].Countries

select * from INFORMATION_SCHEMA.columns
where column_name = 'CityId'

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос
/*
запрос выводит имя продавца, дату продажи, общую сумму в инвойсе и общую сумму
по проданным товарам. Фильтрация происходит по условию, что общая сумма меньше 27

Что касается оптимизации, нужно хорошо знать базу, работать с ней каждый день и знать таблицы,
поэтому пока оптимизировать не получается. Но как вариант, можно по максимуму избавиться от 
подзапросов и переписать на временные таблицы. Слишком замудрённый запрос, может, чуть позже смогу
разобраться в аналитике, пока сложновато.
*/


SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: напишите здесь свое решение
