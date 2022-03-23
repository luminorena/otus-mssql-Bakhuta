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

--исправленный
/*
условие было неправильное, ошибка локализуется, если вывести IsSalesperson первым столбцом, в первом случае будут нули, а во 
втором единицы, то есть как раз продажники.
*/

select p.* from [Application].people p
where  IsSalesperson = 1 and not exists (select * from Sales.Invoices i
where i.ContactPersonID = p.PersonID 
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

--CTE

;with preselectData as
(
select CustomerName, TransactionAmount from sales.CustomerTransactions ct
join sales.Customers c on ct.CustomerID = c.CustomerID
)
select distinct top 5 CustomerName, TransactionAmount from preselectData
group by CustomerName, TransactionAmount
order by TransactionAmount desc

-- подзапрос
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

select  CityId, CityName, sc.CustomerID, ws.StockItemName, ws.UnitPrice
, PackedByPersonID, ap.FullName
from [Application].Cities ac
join Sales.Customers sc on ac.CityID = sc.DeliveryCityID
join sales.Orders so on sc.CustomerId = so.CustomerID
join sales.OrderLines sol on sol.OrderID = so.OrderID
join Warehouse.StockItems ws on ws.StockItemID = sol.StockItemID
join sales.Invoices si on si.OrderID = so.OrderID
join [Application].People ap on ap.PersonID = si.PackedByPersonID
where sol.UnitPrice in (select top 3 UnitPrice from Warehouse.StockItems ws order by UnitPrice desc)
order by ws.UnitPrice desc



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
по проданным товарам. Фильтрация происходит по условию, что общая сумма больше 27000. 

Что касается оптимизации, сам запрос отрабатывает за 0.409секунды, оптимизировать по факту нечего.
Ещё нужно хорошо знать базу, работать с ней каждый день и знать таблицы,
поэтому пока оптимизировать не получается. Но как вариант, можно по максимуму избавиться от 
подзапросов и переписать на временные таблицы (те куски, где тяжелые запросы, а тут
таких нет). Слишком замудрённый запрос по логике, тяжело понимается, может, чуть позже смогу
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
