/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

drop table if exists #tempInvoices;

select InvoiceID, c.CustomerName, InvoiceDate, 
sum(UnitPrice * sol.Quantity) as sumPrice into #tempInvoices
from sales.Invoices i
join sales.Customers c on i.CustomerID = c.CustomerID
join sales.OrderLines sol on i.OrderID = sol.OrderID
group by InvoiceID, c.CustomerName, InvoiceDate
having year(InvoiceDate) >= 2015 

drop table if exists #monthInvoices;
select year(InvoiceDate) InvoiceYear, month(InvoiceDate) InvoiceMonth, sum(sumPrice) monthSum
into #monthInvoices
from #tempInvoices group by year(InvoiceDate), month(InvoiceDate);


with cumSum as (
	select u.InvoiceYear, u.InvoiceMonth, sum(c.monthSum) cumulativeSum
	from #monthInvoices c 
	join #monthInvoices u on c.InvoiceYear < u.InvoiceYear or c.InvoiceYear = u.InvoiceYear and c.InvoiceMonth <= u.InvoiceMonth
	group by u.InvoiceYear, u.InvoiceMonth
)
select t.*, cumulativeSum from #tempInvoices t
join cumSum on cumSum.InvoiceYear = year(InvoiceDate) and cumSum.InvoiceMonth = month(InvoiceDate)
order by InvoiceDate, InvoiceID


/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/
set statistics time, io on
select *, 
sum(sumPrice) over (order by year(InvoiceDate), month(InvoiceDate)) as cumulativeSum
from (
	select InvoiceID, c.CustomerName, InvoiceDate, 
	sum(UnitPrice * sol.Quantity) as sumPrice
	from sales.Invoices i
	join sales.Customers c on i.CustomerID = c.CustomerID
	join sales.OrderLines sol on i.OrderID = sol.OrderID
	where year(InvoiceDate) >= 2015 
	group by InvoiceID, c.CustomerName, InvoiceDate--, UnitPrice, sol.Quantity
) a
order by InvoiceDate, InvoiceID

/*
запрос с оконной функцией 
SQL Server Execution Times:
CPU time = 344 ms,  elapsed time = 881 ms.

запрос без оконной функции
SQL Server Execution Times:
CPU time = 156 ms,  elapsed time = 682 ms.

Получилось, что без оконной функции и с временными таблицами работает быстрее, но это велосипед. 
Очень долго пыталась понять, как надо делать без оконных в принципе.
*/

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/


;with rowNumberCte as(
select si.InvoiceDate, StockItemName,wst.StockItemID,
ROW_NUMBER() over(partition by month(si.InvoiceDate) order by wst.StockItemId) as rn
from Warehouse.StockItems wst
join sales.InvoiceLines sil on wst.StockItemID = sil.StockItemID
join sales.Invoices si on si.InvoiceID = sil.InvoiceID
where year(si.InvoiceDate) = 2016
)
select InvoiceDate, StockItemName, rn from rowNumberCte where rn <=2
order by rowNumberCte.StockItemID, InvoiceDate



/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* + пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* + посчитайте общее количество товаров и выведете полем в этом же запросе
* + посчитайте общее количество товаров в зависимости от первой буквы названия товара
* + отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* + предыдущий ид товара с тем же порядком отображения (по имени)
* + названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* + сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

select 
	   StockItemID
	  , StockItemName
	  , Brand
	  , RecommendedRetailPrice
	  , ROW_NUMBER() over(partition by left(StockItemName,1) order by  StockItemName) as namedByFirstSign
	  , count(*) over() as total
	  , count(*) over (partition by left(StockItemName,1) order by StockItemName) as totalBasedOnFirstSign
	  , lead(StockItemId) over (order by StockItemName) as nextStockItemId
	  , lag(StockItemId) over (order by StockItemName) as previousStockItemId
	  , lag(StockItemName, 2, 'No items') over (order by StockItemName) as prevStockItemName
	  , ntile(30) over (order by TypicalWeightPerUnit) as ntileWeight
from Warehouse.StockItems
order by StockItemName


/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

;with preselect as (
select ap.PersonId, ap.FullName, sc.CustomerId, CustomerName,
sct.TransactionDate, sct.TransactionAmount
, Row_number() over (partition by i.SalespersonPersonID order by sct.TransactionDate) as rnk
from sales.Invoices si
join Sales.CustomerTransactions sct on si.InvoiceId = sct.InvoiceId
join Sales.Customers sc on sc.CustomerId = sct.CustomerId
join sales.Invoices i on i.InvoiceId = si.InvoiceId
join [Application].People ap on ap.PersonId = i.SalespersonPersonID)
select * from preselect
where rnk = 1
order by TransactionDate desc


/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

select c.CustomerId, c.CustomerName, StockItemID, UnitPrice, InvoiceDate from (
select CustomerId, StockItemID, InvoiceDate, UnitPrice
, RANK() over(partition by CustomerId order by UnitPrice desc) as rankPrice
from sales.Invoices si
join sales.InvoiceLines sil on si.InvoiceID = sil.InvoiceID
) a
join sales.Customers c on c.CustomerID = a.CustomerID
where rankPrice <=2
order by UnitPrice, CustomerID 
