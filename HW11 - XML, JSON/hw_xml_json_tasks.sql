/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit,
LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 
Сделать два варианта: с помощью OPENXML и через XQuery.

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 
*/
--OpenXML

--загрузка записей с диска
use WideWorldImporters
DECLARE @xmlDocument  xml
SELECT @xmlDocument = BulkColumn
FROM OPENROWSET
(BULK 'D:\MSSQL Developer\11 - XML, JSON\StockItems-188-1fb5df.xml', 
 SINGLE_CLOB)
as data 

DECLARE @docHandle int
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument


select * into #StockItemsTemp   
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
	[SupplierID] int  'SupplierID',
	StockItemName nvarchar(100) '@Name',
	[UnitPackageID] int 'Package/UnitPackageID',
	[OuterPackageID] int 'Package/OuterPackageID',
	[QuantityPerOuter] int 'Package/QuantityPerOuter',
	[TypicalWeightPerUnit] decimal(18,3) 'Package/TypicalWeightPerUnit',
	[LeadTimeDays] int 'LeadTimeDays',
	[IsChillerStock] bit 'IsChillerStock',
	[TaxRate] decimal(18,3) 'TaxRate',
	[UnitPrice] decimal(18,2) 'UnitPrice'
	)

EXEC sp_xml_removedocument @docHandle


/*
Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить 
(сопоставлять записи по полю StockItemName). 
*/
select * from #StockItemsTemp 
merge Warehouse.StockItems as target
using (values (4, N'"The Gu" red shirt XML tag t-shirt (Black) 3XXL',7, 6, 12, 0.400, 7, 0, 20.000, 18.00, 1),
(5, N'Developer joke mug (Yellow)', 7, 7, 10, 0.600, 12, 0, 20.000, 1.50, 1),
(4, N'Dinosaur battery-powered slippers (Green) L', 7,7,1, 0.350, 12, 0, 20.000, 16.00, 1),
(4, N'Dinosaur battery-powered slippers (Green) M', 7, 7, 1, 0.350, 12, 0, 20.000, 48.00, 1),
(4, N'Dinosaur battery-powered slippers (Green) S', 7, 7, 1, 0.350, 12, 0, 20.000, 32.00, 1),
(4, N'Furry gorilla with big eyes slippers (Black) XL', 7, 7, 1, 0.400, 12, 0, 20.000, 32.00, 1),
(7, N'Large  replacement blades 18mm', 7, 7, 10, 0.800, 21, 0, 20.000, 2.45, 1),
(7, N'Large sized bubblewrap roll 50m', 7, 7, 10, 10.000, 14, 0, 20.000, 36.00, 1),
(7, N'Medium sized bubblewrap roll 20m', 7, 7, 10, 6.000, 14, 0, 20.000, 20.00, 1),
(7, N'Shipping carton (Brown) 356x229x229mm', 7,7, 25, 0.400, 14, 0, 20.000, 1.14, 1),
(7, N'Shipping carton (Brown) 356x356x279mm', 7, 7, 25, 0.300, 14, 0, 20.000, 3.06, 1),
(7, N'Shipping carton (Brown) 413x285x187mm', 7, 7, 25, 0.350, 14, 0, 20.000, 0.34, 1),
(7, N'Shipping carton (Brown) 457x279x279mm', 7, 7, 25, 0.400, 14, 0, 20.000, 1.92, 1),
(12, N'USB food flash drive - sushi roll', 7, 7, 1, 0.050, 14, 0, 20.000, 32.00, 1),
(12, N'USB missile launcher (Green)', 7, 7, 1, 0.300, 14, 0, 20.000, 25.00, 1)
)
as source (SupplierId, StockItemName, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit,
LeadTimeDays, IsChillerStock, TaxRate, UnitPrice, LastEditedBy)
on (target.StockItemName = source.StockItemName)
when matched 
then update
set SupplierId = source.SupplierId, StockItemName = source.StockItemName, UnitPackageID = source.UnitPackageID,
OuterPackageID = source.OuterPackageID, QuantityPerOuter = source.QuantityPerOuter, 
TypicalWeightPerUnit = source.TypicalWeightPerUnit, LeadTimeDays = source.LeadTimeDays, 
IsChillerStock = source.IsChillerStock, TaxRate = source.TaxRate, UnitPrice = source.UnitPrice, 
LastEditedBy = source.LastEditedBy
when not matched
then insert (SupplierId, StockItemName, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit,
LeadTimeDays, IsChillerStock, TaxRate, UnitPrice, LastEditedBy)
values (source.SupplierId, source.StockItemName, source.UnitPackageID, source.OuterPackageID, 
source.QuantityPerOuter, source.TypicalWeightPerUnit,source.LeadTimeDays, source.IsChillerStock, 
source.TaxRate, source.UnitPrice, source.LastEditedBy)
output deleted.*, $action, inserted.*;

drop table if exists #StockItemsTemp

--XQuery
go
DECLARE @x XML
SET @x = ( 
  SELECT * FROM OPENROWSET
  (BULK 'D:\MSSQL Developer\11 - XML, JSON\StockItems-188-1fb5df.xml',
   SINGLE_CLOB) as d)
select t.Item.value('(@Name)[1]', 'nvarchar(max)') as [Name],
t.Item.value('(Package/UnitPackageID)[1]','int') as [UnitPackageID],
t.Item.value('(Package/OuterPackageID)[1]','int') as [OuterPackageID],
t.Item.value('(Package/QuantityPerOuter)[1]','int') as [QuantityPerOuter],
t.Item.value('(Package/TypicalWeightPerUnit)[1]','decimal(18,3)') as [TypicalWeightPerUnit],
t.Item.value('(LeadTimeDays)[1]','int') as [LeadTimeDays],
t.Item.value('(IsChillerStock)[1]','bit') as [IsChillerStock],
t.Item.value('(TaxRate)[1]','decimal(18,3)') as [TaxRate],
t.Item.value('(UnitPrice)[1]','decimal(18,3)') as [UnitPrice]
from @x.nodes ('/StockItems/Item') as t(Item)


/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

-- простой вывод - ок

select StockItemName as [Item/@Name]
	  , SupplierId as [SupplierId]
	  , UnitPackageID as [Package/UnitPackageID]
	  , OuterPackageID as [Package/OuterPackageID]
	  , QuantityPerOuter as [Package/QuantityPerOuter]
	  , TypicalWeightPerUnit as [Package/TypicalWeightPerUnit]
	  , LeadTimeDays as [LeadTimeDays]
	  , IsChillerStock as [IsChillerStock]
	  , TaxRate as [TaxRate]
	  , UnitPrice as [UnitPrice]
from Warehouse.StockItems
where StockItemName in 
(N'"The Gu" red shirt XML tag t-shirt (Black) 3XXL', 'Developer joke mug (Yellow)',
'Dinosaur battery-powered slippers (Green) L','Dinosaur battery-powered slippers (Green) M',
'Dinosaur battery-powered slippers (Green) S', 'Furry gorilla with big eyes slippers (Black) XL',
'Large  replacement blades 18mm','Large sized bubblewrap roll 50m','Medium sized bubblewrap roll 20m',
'Shipping carton (Brown) 356x229x229mm','Shipping carton (Brown) 356x356x279mm', 
'Shipping carton (Brown) 413x285x187mm', 'Shipping carton (Brown) 457x279x279mm',
'USB food flash drive - sushi roll','USB missile launcher (Green)')
order by StockItemName
for XML PATH ('StockItems'), ROOT ('StockItems')

-- выгрузка не получается надо вставить во временную таблицу тип XML,
-- The FOR XML clause is not allowed in a SELECT INTO statement.
create table #StockTemp
(col xml)


--загрузка в XML файл дальше из временной таблицы. Если весь запрос писать, там сложности
--с экранированием.

DECLARE @cmd VARCHAR(5000);
SET @cmd = 'bcp.exe "select * from #StockTemp" queryout D:\temp.xml -w -r -T';

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

select
	StockItemID
   ,StockItemName
   ,JSON_VALUE (CustomFields, '$.CountryOfManufacture') as CountryOfManufacture
   ,JSON_VALUE (CustomFields, '$.Tags[0]') as Tags
from Warehouse.StockItems


/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/
-- вывод по условию с тегом Vintage

; with tempCTE as (
select	StockItemID
		,StockItemName
		,CustomFields
		,tags.[key]
		,tags.value
from Warehouse.StockItems
Cross Apply OpenJson(CustomFields, '$.Tags')  as tags
where tags.value = 'Vintage')
select StockItemID
	   ,StockItemName
	   ,CustomFields
	   from tempCTE

--все теги (из CustomFields) через запятую в одном поле
;with cte as (
select	StockItemID
		,StockItemName
		,CustomFields
		,tags.[key]
		,tags.value as a
from Warehouse.StockItems
Cross Apply OpenJson(CustomFields, '$.Tags')  as tags
)
select String_Agg(cast(a as nvarchar(max)),',') as  tags
from cte

--через xml - но тут выводится именно в типе XML, почему, так и не поняла
--P.S. последнюю запятую в строчке можно убрать через left (Field, len (Field) -1), в примерах урока так исправила

;with cte as (
select	StockItemID
		,StockItemName
		,CustomFields
		,tags.[key]
		,tags.value as a
from Warehouse.StockItems
Cross Apply OpenJson(CustomFields, '$.Tags')  as tags
)
select a + ', '  as 'data()'
from cte
for xml path ('')





