use VetShop

-- | ѕолнотекстовые индексы | --

--поиск по корму дл€ животных. Ѕерем таблицу dbo.Products


--—оздать полнотекстовый каталог

CREATE FULLTEXT CATALOG VetShop_FT_Catalog
WITH ACCENT_SENSITIVITY = ON
AS DEFAULT
AUTHORIZATION [dbo]
GO

--—оздать полнотекстовый индекс

CREATE FULLTEXT INDEX ON dbo.Products(ProductDescription LANGUAGE Russian)
KEY INDEX PK__Products_ProductId -- первичный ключ
ON (VetShop_FT_Catalog)
WITH (
  CHANGE_TRACKING = AUTO, /* AUTO, MANUAL, OFF */
  STOPLIST = SYSTEM /* SYSTEM, OFF или пользовательский stoplist */
);

-- | «апросы на полнотекстовые индексы | --

-- CONTAINS 
-- где встречаетс€ слово стерилизованных
SELECT *
FROM dbo.Products
WHERE CONTAINS(ProductDescription, N'стерилизованных');

-- поиск по словоформам
SELECT *
FROM dbo.Products
WHERE CONTAINS(ProductDescription, 'FORMSOF(INFLECTIONAL, "кошка")')

-- FREETEXTTABLE

SELECT *
FROM dbo.Products p
INNER JOIN FREETEXTTABLE(dbo.Products, ProductDescription,  N'кошка корм') AS t
ON p.ProductId=t.[KEY]
where Rank > 0
ORDER BY t.RANK DESC

-- |  олоночные индексы | --

/*Ќеобходимо подсчитать общую сумму продаж. ¬ данном случае в базе товары
всего за один год, но если товаров будет больше, этот индекс будет очень кстати,
так как данные нужны по колонкам
*/

CREATE COLUMNSTORE INDEX IX_Index_ColumnStore_Orders_Price
ON dbo.Orders(Quantity, CostPerUnit)
GO

;with cte as
(
select *, Quantity*CostPerUnit as price
from dbo.Orders)
select sum(price) as commonPrice 
from cte 

--xml индексы

select * from ref.EmployeeInfo ei
join workers.Employees e 
on ei.EmployeeID = e.EmployeeID

--таблица - сводка данных по всем работникам

--ѕервоначальный запрос на xml


select ei.EmployeeId as [EmployeeId]
	  , LastName as [GeneralInfo/@LastName]
      , FirstName as [GeneralInfo/@FirstName]
	  , MiddleName as [GeneralInfo/@MiddleName]
	  , Gender as [GeneralInfo/@Gender]
	  , PhoneNumber as [EmployeeData/PhoneNumber]
	  , EmployeeAddress as [EmployeeAddress]
from ref.EmployeeInfo ei
join workers.Employees e 
on ei.EmployeeID = e.EmployeeID
where ei.EmployeeID = 1 -- здесь изменить айдишник
order by ei.EmployeeID
for XML PATH ('Employee'), ROOT ('EmployeeInfo')

--ƒобавление данных в таблицу

drop table if exists ref.EmployeeInfoSummary

create table ref.EmployeeInfoSummary
(EmployeeSummary xml)

DECLARE @x XML
SELECT @x = (select ei.EmployeeId as [EmployeeId]
	  , LastName as [GeneralInfo/@LastName]
      , FirstName as [GeneralInfo/@FirstName]
	  , MiddleName as [GeneralInfo/@MiddleName]
	  , Gender as [GeneralInfo/@Gender]
	  , PhoneNumber as [EmployeeData/PhoneNumber]
	  , EmployeeAddress as [EmployeeAddress]
from ref.EmployeeInfo ei
join workers.Employees e 
on ei.EmployeeID = e.EmployeeID
where ei.EmployeeID = 1
order by ei.EmployeeID
for XML PATH ('Employee'), ROOT ('EmployeeInfo'))
INSERT into ref.EmployeeInfoSummary values (@x)

select * from ref.EmployeeInfoSummary

--ref.EmployeeInfoSummary св€зана ref.EmployeeInfo


-- создаем первичный ключ с кластерным индексом
ALTER TABLE ref.EmployeeInfoSummary
   ADD CONSTRAINT FK_EmployeeInfoId PRIMARY KEY CLUSTERED (SummaryID);

--Primary index

CREATE PRIMARY XML INDEX [XML_Primary_EmployeeInfoSummary]
ON ref.EmployeeInfoSummary ([EmployeeSummary])
GO

--индекс вторичный на for path
CREATE XML INDEX [XML_SecondaryPATH_EmployeeSummary]
ON ref.EmployeeInfoSummary (EmployeeSummary)
USING XML INDEX [XML_Primary_EmployeeInfoSummary] 
FOR PATH
GO

--индекс вторичный на value

CREATE XML INDEX [XML_SecondaryVALUE_EmployeeSummary]
ON ref.EmployeeInfoSummary (EmployeeSummary)
USING XML INDEX [XML_Primary_EmployeeInfoSummary] 
FOR VALUE
GO


	  