use VetShop

-- | �������������� ������� | --

--����� �� ����� ��� ��������. ����� ������� dbo.Products


--������� �������������� �������

CREATE FULLTEXT CATALOG VetShop_FT_Catalog
WITH ACCENT_SENSITIVITY = ON
AS DEFAULT
AUTHORIZATION [dbo]
GO

--������� �������������� ������

CREATE FULLTEXT INDEX ON dbo.Products(ProductDescription LANGUAGE Russian)
KEY INDEX PK__Products_ProductId -- ��������� ����
ON (VetShop_FT_Catalog)
WITH (
  CHANGE_TRACKING = AUTO, /* AUTO, MANUAL, OFF */
  STOPLIST = SYSTEM /* SYSTEM, OFF ��� ���������������� stoplist */
);

-- | ������� �� �������������� ������� | --

-- CONTAINS 
-- ��� ����������� ����� ���������������
SELECT *
FROM dbo.Products
WHERE CONTAINS(ProductDescription, N'���������������');

-- ����� �� �����������
SELECT *
FROM dbo.Products
WHERE CONTAINS(ProductDescription, 'FORMSOF(INFLECTIONAL, "�����")')

-- FREETEXTTABLE

SELECT *
FROM dbo.Products p
INNER JOIN FREETEXTTABLE(dbo.Products, ProductDescription,  N'����� ����') AS t
ON p.ProductId=t.[KEY]
where Rank > 0
ORDER BY t.RANK DESC

-- | ���������� ������� | --

/*���������� ���������� ����� ����� ������. � ������ ������ � ���� ������
����� �� ���� ���, �� ���� ������� ����� ������, ���� ������ ����� ����� ������,
��� ��� ������ ����� �� ��������
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

--xml �������

select * from ref.EmployeeInfo ei
join workers.Employees e 
on ei.EmployeeID = e.EmployeeID

--������� - ������ ������ �� ���� ����������

--�������������� ������ �� xml


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
where ei.EmployeeID = 1 -- ����� �������� ��������
order by ei.EmployeeID
for XML PATH ('Employee'), ROOT ('EmployeeInfo')

--���������� ������ � �������

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

--ref.EmployeeInfoSummary ������� ref.EmployeeInfo


-- ������� ��������� ���� � ���������� ��������
ALTER TABLE ref.EmployeeInfoSummary
   ADD CONSTRAINT FK_EmployeeInfoId PRIMARY KEY CLUSTERED (SummaryID);

--Primary index

CREATE PRIMARY XML INDEX [XML_Primary_EmployeeInfoSummary]
ON ref.EmployeeInfoSummary ([EmployeeSummary])
GO

--������ ��������� �� for path
CREATE XML INDEX [XML_SecondaryPATH_EmployeeSummary]
ON ref.EmployeeInfoSummary (EmployeeSummary)
USING XML INDEX [XML_Primary_EmployeeInfoSummary] 
FOR PATH
GO

--������ ��������� �� value

CREATE XML INDEX [XML_SecondaryVALUE_EmployeeSummary]
ON ref.EmployeeInfoSummary (EmployeeSummary)
USING XML INDEX [XML_Primary_EmployeeInfoSummary] 
FOR VALUE
GO


	  