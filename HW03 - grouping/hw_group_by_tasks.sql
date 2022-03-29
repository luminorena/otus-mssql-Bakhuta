/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select
		grouping (year(InvoiceDate)) as grouping_year
	   ,grouping (month(InvoiceDate)) as grouping_month
	   ,year(InvoiceDate) as [year]
	   ,month(InvoiceDate) as [month]
	   ,avg(UnitPrice) as avgPrice 
	   from Sales.Invoices si
join sales.OrderLines sol on si.OrderID = sol.OrderID
group by rollup (year(InvoiceDate), month(InvoiceDate)), UnitPrice
order by  [month] desc 

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select	year(InvoiceDate) as [year]
	   ,month(InvoiceDate) as [month]
	   ,sum(UnitPrice * sol.Quantity) as sumPrice 
	   from Sales.Invoices si
join sales.OrderLines sol on si.OrderID = sol.OrderID
group by month(InvoiceDate), year(InvoiceDate)
having sum(UnitPrice * sol.Quantity) > 10000


/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select year(so.OrderDate) as [year], month(so.OrderDate) as [month], sol.[Description]
, sum(sol.PickedQuantity * sol.UnitPrice) as [sum], si.InvoiceDate
,sol.PickedQuantity
from sales.Invoices si
join sales.Orders so on si.OrderID = so.OrderID
join sales.OrderLines sol on sol.OrderID = si.OrderID
group by year(so.OrderDate), month(so.OrderDate), 
sol.[Description], sol.PickedQuantity, si.InvoiceDate
having sum(sol.PickedQuantity * sol.UnitPrice) < 50


-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/

/*
Ваш комментарий:
По опциональному заданию - можно просто "захардкодить" таблицу с месяцами, годами в коде и
потом ее соединить с данными через left join - нули там "автоматом" появятся, case не нужен.
*/


drop table if exists #monthTable
drop table if exists #yearTable
Declare @maxMonth INT = 12;
WITH GenId (Id) AS 
(	
	SELECT 1 
	UNION ALL
	SELECT GenId.Id + 1
	FROM GenId 
	WHERE GenId.Id < @maxMonth
)
Select * into #monthTable
from GenId
OPTION (MAXRECURSION 12);

Declare @maxYear INT = (select max(year(InvoiceDate)) from Sales.Invoices),
	@minYear INT = (select min(year(InvoiceDate)) from Sales.Invoices);
WITH GenId (Id) AS 
(	
	SELECT @minYear 
	UNION ALL
	SELECT GenId.Id + 1
	FROM GenId 
	WHERE GenId.Id < @maxYear
)
Select * into #yearTable
from GenId;


select * from #monthTable
select * from #yearTable

--2

select	y.Id as [year]
	   ,m.Id as [month]
	   ,isNull(sum(UnitPrice * sol.Quantity), 0) as sumPrice 
from #yearTable y
cross join #monthTable m
left join Sales.Invoices si on m.Id = month(InvoiceDate) and y.Id = year(InvoiceDate)
left join sales.OrderLines sol on si.OrderID = sol.OrderID
group by y.Id, m.Id
order by  [year], [month]



--3
select  y.Id as [year]
	    ,m.Id as [month]
		,[Description]
	    ,isNull(sum(UnitPrice * sol.Quantity), 0) as sumPrice 
	    ,InvoiceDate
        ,isNull (sol.PickedQuantity, 0) as PickedQuantity
from #yearTable y
cross join #monthTable m
left join sales.Invoices si on m.Id = month(InvoiceDate) and y.Id = year(InvoiceDate)
left join sales.Orders so on si.OrderID = so.OrderID
left join sales.OrderLines sol on sol.OrderID = si.OrderID
group by y.Id, m.Id, sol.[Description], si.InvoiceDate,sol.PickedQuantity
order by  [year], [month]


