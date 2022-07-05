use VetShop

--создадим файловую группу
ALTER DATABASE [VetShop] ADD FILEGROUP [SalesData]
GO

--добавляем файл БД
ALTER DATABASE [VetShop] ADD FILE 
(NAME = N'SaleDate', FILENAME = N'D:\ms sql backups\SalesData.ndf' , 
SIZE=4MB, MAXSIZE=10MB,FILEGROWTH=1MB ) TO FILEGROUP [SalesData]
GO

drop function if exists [fnSaleDatePartition]
--создаем функцию партиционирования по годам - по умолчанию left!!
CREATE PARTITION FUNCTION [fnSalesDatePartition](DATE) AS RANGE right FOR VALUES
('20190101','20200101','20220101');																																																									
GO


-- партиционируем, используя созданную нами функцию
CREATE PARTITION SCHEME [schmSalesDatePartition] AS PARTITION [fnSalesDatePartition] 
ALL TO ([SalesData])
GO


--создаем отдельно секционированную таблицу, так как для удаления кластерного индекса нужно будет
--отдельно пересоздавать связи и ключи, sales.Orders -  одна из основных таблиц в базе
--секционирование нужно планировать на этапе проектирования

SELECT * INTO Sales.OrdersPartitioned
FROM Sales.Orders

select * from Sales.OrdersPartitioned

--создадим кластерный индекс в той же схеме с тем же ключом
ALTER TABLE [Sales].[Orders] ADD CONSTRAINT PK_Sales_OrdersPartitioned 
PRIMARY KEY CLUSTERED  (OrderId, SaleDate)
ON [schmSalesDatePartition]([SaleDate]);

--просмотр результата

--секционированные таблицы в базе данных

select distinct t.name
from sys.partitions p
inner join sys.tables t
	on p.object_id = t.object_id
where p.partition_number <> 1

--диапазоны секционирования
SELECT  $PARTITION.fnSaleDatePartition(SaleDate) AS Partition
		, COUNT(*) AS [count]
		, MIN(SaleDate) as [min]
		,MAX(SaleDate) as [max]
FROM Sales.Orders
GROUP BY $PARTITION.fnSaleDatePartition(SaleDate) 
ORDER BY Partition ;  


