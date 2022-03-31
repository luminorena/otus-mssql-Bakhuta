/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

insert into Sales.Customers
(CustomerId,CustomerName, BillToCustomerId,CustomerCategoryId, 
PrimaryContactPersonId, AccountOpenedDate, AlternateContactPersonId,
DeliveryMethodId,DeliveryCityId, PostalCityId,StandardDiscountPercentage, 
IsStatementSent, IsOnCreditHold,PaymentDays, PhoneNumber,FaxNumber, WebsiteURL,DeliveryAddressLine1,
DeliveryPostalCode, PostalAddressLine1, PostalPostalCode, LastEditedBy)
values
(NEXT VALUE FOR Sequences.CustomerId, 'firstCustomer', 1, 1, 1, '2000-02-02', 1, 1, 1, 1, 10,
1, 1, 12, N'(495)455-456',N'(495)123-345', 'https://test.com', 'test1','test2','test3',34, 1),
(NEXT VALUE FOR Sequences.CustomerId, 'secondCustomer', 1, 1, 1, '2000-02-02', 1, 1, 1, 1, 10,
1, 1, 12, N'(495)455-456',N'(495)123-345', 'https://test.com', 'test1','test2','test3',34, 1),
(NEXT VALUE FOR Sequences.CustomerId, 'thirdCustomer', 1, 1, 1, '2000-02-02', 1, 1, 1, 1, 10,
1, 1, 12, N'(495)455-456',N'(495)123-345', 'https://test.com', 'test1','test2','test3',34, 1),
(NEXT VALUE FOR Sequences.CustomerId, 'fourthCustomer', 1, 1, 1, '2000-02-02', 1, 1, 1, 1, 10,
1, 1, 12, N'(495)455-456',N'(495)123-345', 'https://test.com', 'test1','test2','test3',34, 1),
(NEXT VALUE FOR Sequences.CustomerId, 'fifthCustomer', 1, 1, 1, '2000-02-02', 1, 1, 1, 1, 10,
1, 1, 12, N'(495)455-456',N'(495)123-345', 'https://test.com', 'test1','test2','test3',34, 1)

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

delete from sales.Customers
where CustomerName = 'firstCustomer'

select * from sales.Customers
where CustomerID = Any (select max(CustomerID) from sales.Customers)

/*
3. Изменить одну запись, из добавленных через UPDATE
*/


update sales.Customers 
set CustomerName = 'customerUpdated'
where CustomerID = Any (select max(CustomerID) from sales.Customers)



/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

/*
Чтобы получилось равенство Action=Update, надо в поле CustomerName в исходном селекте поставить 
существующее значение, например, Tailspin Toys (Head Office).
Форматировать не стала, скрипт получился бы просто гигантским.
*/
Merge sales.Customers as target
using(
select 'RandomХ', 1, 1, 2, 1,'2013-01-01', 34, 10, 11, 4, 0, 3, 1, 7, N'445-445', 
'(496)454-456', 'http://www.random.com', 'Shop 1', 1233, 'Box X', 23455, 1
)
as source (CustomerName, BillToCustomerId, CustomerCategoryId, BuyingGroupId, 
PrimaryContactPersonId, AccountOpenedDate, AlternateContactPersonId, DeliveryMethodId,
DeliveryCityId, PostalCityId, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, 
PaymentDays, PhoneNumber,FaxNumber, WebsiteURL, DeliveryAddressLine1, DeliveryPostalCode, 
PostalAddressLine1, PostalPostalCode, LastEditedBy)
on (target.CustomerName = source.CustomerName)
when matched 
then update
set  CustomerName=source.CustomerName, BillToCustomerId=source.BillToCustomerId, 
CustomerCategoryId=source.CustomerCategoryId, BuyingGroupId=source.BuyingGroupId, 
PrimaryContactPersonId=source.PrimaryContactPersonId, AccountOpenedDate = source.AccountOpenedDate,
AlternateContactPersonId=source.AlternateContactPersonId,
DeliveryMethodId=source.DeliveryMethodId, DeliveryCityId=source.DeliveryCityId, 
PostalCityId=source.PostalCityId,StandardDiscountPercentage=source.StandardDiscountPercentage, 
IsStatementSent=source.IsStatementSent, IsOnCreditHold=source.IsOnCreditHold,
PaymentDays = source.PaymentDays, PhoneNumber=source.PhoneNumber,FaxNumber=source.FaxNumber, 
WebsiteURL = source.WebsiteURL, DeliveryAddressLine1 = source.DeliveryAddressLine1, 
DeliveryPostalCode = source.DeliveryPostalCode, PostalAddressLine1 = source.PostalAddressLine1,
PostalPostalCode = source.PostalPostalCode, LastEditedBy = source.LastEditedBy
when not matched
then insert (CustomerName, BillToCustomerId,CustomerCategoryId, 
PrimaryContactPersonId, AccountOpenedDate, AlternateContactPersonId,
DeliveryMethodId,DeliveryCityId, PostalCityId,StandardDiscountPercentage, 
IsStatementSent, IsOnCreditHold,PaymentDays, PhoneNumber,FaxNumber, WebsiteURL,DeliveryAddressLine1,
DeliveryPostalCode, PostalAddressLine1, PostalPostalCode, LastEditedBy)
values(source.CustomerName, source.BillToCustomerId,source.CustomerCategoryId, 
source.PrimaryContactPersonId, source.AccountOpenedDate, source.AlternateContactPersonId,
source.DeliveryMethodId, source.DeliveryCityId, 
source.PostalCityId,source.StandardDiscountPercentage, 
source.IsStatementSent, source.IsOnCreditHold, source.PaymentDays,
source.PhoneNumber,source.FaxNumber, source.WebsiteURL, source.DeliveryAddressLine1, 
source.DeliveryPostalCode, source.PostalAddressLine1, source.PostalPostalCode, source.LastEditedBy)
OUTPUT deleted.*, $action, inserted.*;
/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузит через bulk insert
*/

/*
ключ -S не нужен, так как у меня один инстанс sql-сервера установлен
*/
exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.Invoices" out  "D:\Invoices1.csv" -T -w -t;'

drop table if exists Sales.Invoices_bulked
select * into Sales.Invoices_bulked
from sales.Invoices
where 1=2


BULK INSERT Sales.Invoices_bulked
				   FROM "D:\Invoices1.csv"
				   WITH 
					 (
						BATCHSIZE = 1000, 
						DATAFILETYPE = 'widechar', --unicode characters
						FIELDTERMINATOR = ';',
						ROWTERMINATOR ='\n',
						KEEPNULLS,
						TABLOCK        
					  );

select * from Sales.Invoices_bulked

