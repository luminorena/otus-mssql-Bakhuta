--Оптимизируйте запрос по БД WorldWideImporters.
--Приложите текст запроса со статистиками по времени и операциям ввода вывода,
--опишите кратко ход рассуждений при оптимизации.
use WideWorldImporters

DBCC FREEPROCCACHE

SET STATISTICS IO ON 
SET STATISTICS time ON 

Select ord.CustomerID, det.StockItemID, 
SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord
JOIN Sales.OrderLines AS det
ON det.OrderID = ord.OrderID
JOIN Sales.Invoices AS Inv
ON Inv.OrderID = ord.OrderID
JOIN Sales.CustomerTransactions AS Trans
ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions AS ItemTrans
ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
AND (Select SupplierId
FROM Warehouse.StockItems AS It
Where It.StockItemID = det.StockItemID) = 12
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID


--Оптимизация

SET STATISTICS IO ON 
SET STATISTICS time ON
DROP TABLE if exists #temptable; 

create table #temptable
(
CustomerId int,
StockItemId int,
UnitPriceSum float,
Quantity int,
OrderId int
)

insert into #temptable
(CustomerId, StockItemId, UnitPriceSum, Quantity, OrderId)
Select ord.CustomerID, det.StockItemID, 
SUM(det.UnitPrice) as UnitPriceSum, SUM(det.Quantity) as Quantity,
COUNT(ord.OrderID) as OrderID
FROM Sales.Orders AS ord
JOIN Sales.OrderLines AS det
ON det.OrderID = ord.OrderID
JOIN Sales.Invoices AS Inv
ON Inv.OrderID = ord.OrderID
JOIN Sales.CustomerTransactions AS Trans
ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions AS ItemTrans
ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

;with preselect as
(
select t.* from #temptable t
join Warehouse.StockItems as It
on It.StockItemID = t.StockItemID
where SupplierID = 12
),
preselect2 as (
select p.*, sum(UnitPriceSum*p.Quantity) as sum
from preselect p
join Sales.OrderLines ord
on p.OrderId = ord.OrderID
where CustomerId = CustomerId
group by UnitPriceSum, p.Quantity,
p.CustomerId, p.StockItemId, p.OrderId
)
select p.CustomerId, p.StockItemId, p.UnitPriceSum, p.Quantity, p.OrderID
from preselect2 p
order by p.CustomerId, p.StockItemId



