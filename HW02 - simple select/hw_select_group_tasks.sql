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
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select StockItemName
from Warehouse.StockItems
where StockItemName like '%urgent%' or StockItemName like 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select ps.SupplierID, ps.SupplierName from Purchasing.Suppliers ps
left join Purchasing.PurchaseOrders ppo
on ps.SupplierID = ppo.SupplierID
where PurchaseOrderID is null


/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/
-- если надо выводить на русском языке названия месяцев, включить опцию
--SET LANGUAGE Russian
select  so.OrderID
		,convert(nvarchar(10), OrderDate, 104) as OrderDate
		,month(OrderDate) as [MonthNumber]
		,datename(month, OrderDate) as [MonthName]
		,datepart("q", OrderDate) as [Quarter]
		,case 
			when 12/month(OrderDate) <= 4 then 1
			when (12/month(OrderDate) > 4 and 12/month(OrderDate) <=8) then 2
			when 12/month(OrderDate) > 9 then 3 
			end as ThirdOfTheYear
	    ,CustomerName
from Sales.Orders so
join Sales.OrderLines sol 
on so.OrderID = sol.OrderID
join Sales.Customers sc on 
sc.CustomerID = so.CustomerID
where (UnitPrice > 100 or Quantity > 20) and so.PickingCompletedWhen is not null
order by [Quarter], ThirdOfTheYear, OrderDate
offset 1000 rows fetch first 100 rows only

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select adm.DeliveryMethodName
	   ,pso.ExpectedDeliveryDate
	   ,ps.SupplierName
	   ,ap.FullName	   
from Purchasing.Suppliers ps
join Purchasing.PurchaseOrders pso
on ps.SupplierID = pso.SupplierID
join [Application].DeliveryMethods adm
on adm.DeliveryMethodID = pso.DeliveryMethodID
join [Application].People ap on ap.PersonID = pso.ContactPersonID
where year(pso.ExpectedDeliveryDate) = 2013 and month(pso.ExpectedDeliveryDate) = 1
and (DeliveryMethodName = 'Air Freight' or DeliveryMethodName = 'Refrigerated Air Freight')
and IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

select top 10 
	   sp.OrderID
	   ,sp.OrderDate
	   ,sc.CustomerName 
	   ,ap.FullName
	   from sales.Orders sp
join [Application].People ap
on sp.ContactPersonID = ap.PersonID
join sales.Customers sc on sc.CustomerID = sp.CustomerID
where ap.IsSalesperson = 0
order by sp.OrderDate desc


/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select sc.CustomerID, sc.CustomerName, sc.PhoneNumber
from sales.Customers sc
join sales.Orders so on so.CustomerID = sc.CustomerID
join sales.OrderLines sol on sol.OrderID = so.OrderID
join Warehouse.StockItems wsi on wsi.StockItemID = sol.StockItemID
where StockItemName = 'Chocolate frogs 250g'


