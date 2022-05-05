--Create Database

CREATE DATABASE [VetShop]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'VetShop', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\VetShop.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'VetShop_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\VetShop_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO

--Deseases
CREATE TABLE [animals].[Deseases](
	[DeseaseId] [int] NOT NULL,
	[DeseaseName] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK__Animals_DeseaseId] PRIMARY KEY CLUSTERED 
(
	[DeseaseId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

--Medicaments
CREATE TABLE [animals].[Medicaments](
	[MedicamentId] [int] NOT NULL,
	[DeseaseId] [int] NOT NULL,
	[MedicamentName] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK__Medicaments_MedicamentId] PRIMARY KEY CLUSTERED 
(
	[MedicamentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [animals].[Medicaments]  WITH CHECK ADD  CONSTRAINT [FK__Medicaments_DeseaseId] FOREIGN KEY([DeseaseId])
REFERENCES [animals].[Deseases] ([DeseaseId])
GO

ALTER TABLE [animals].[Medicaments] CHECK CONSTRAINT [FK__Medicaments_DeseaseId]
GO

--CustomerPayments

CREATE TABLE [dbo].[CustomerPayments](
	[PaymentId] [int] NOT NULL,
	[OrderId] [int] NOT NULL,
	[IsPayedSuccessfully] [bit] NOT NULL,
 CONSTRAINT [PK__CustomerPayments_PaymentId] PRIMARY KEY CLUSTERED 
(
	[PaymentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[CustomerPayments]  WITH CHECK ADD  CONSTRAINT [FK__CustomerPayments_OrderId] FOREIGN KEY([OrderId])
REFERENCES [dbo].[Orders] ([OrderID])
GO

ALTER TABLE [dbo].[CustomerPayments] CHECK CONSTRAINT [FK__CustomerPayments_OrderId]
GO

--Customers

CREATE TABLE [dbo].[Customers](
	[CustomerId] [int] NOT NULL,
	[CustomerName] [nvarchar](100) NOT NULL,
	[DeliveryAddress] [nvarchar](100) NOT NULL,
	[IsConstant] [bit] NOT NULL,
 CONSTRAINT [PK__Customers_CustomerId] PRIMARY KEY CLUSTERED 
(
	[CustomerId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

--Orders

CREATE TABLE [dbo].[Orders](
	[OrderID] [int] NOT NULL,
	[CustomerId] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[CostPerUnit] [decimal](18, 2) NOT NULL,
	[SaleDate] [date] NOT NULL,
 CONSTRAINT [PK__Orders_OrderId] PRIMARY KEY CLUSTERED 
(
	[OrderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Orders]  WITH CHECK ADD  CONSTRAINT [FK__Orders__CustomerId] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([CustomerId])
GO

ALTER TABLE [dbo].[Orders] CHECK CONSTRAINT [FK__Orders__CustomerId]
GO

--Products

CREATE TABLE [dbo].[Products](
	[ProductId] [int] NOT NULL,
	[OrderId] [int] NOT NULL,
	[AnimalId] [int] NOT NULL,
	[ProductDescription] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK__Products_ProductId] PRIMARY KEY CLUSTERED 
(
	[ProductId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Products]  WITH CHECK ADD  CONSTRAINT [FK__Products__AnimalId] FOREIGN KEY([AnimalId])
REFERENCES [animals].[AnimalTypes] ([AnimalId])
GO

ALTER TABLE [dbo].[Products] CHECK CONSTRAINT [FK__Products__AnimalId]
GO

ALTER TABLE [dbo].[Products]  WITH CHECK ADD  CONSTRAINT [FK__Products__OrderId] FOREIGN KEY([OrderId])
REFERENCES [dbo].[Orders] ([OrderID])
GO

--Suppliers

CREATE TABLE [dbo].[Suppliers](
	[SupplierId] [int] NOT NULL,
	[CustomerId] [int] NOT NULL,
	[PhoneNumber] [nvarchar](50) NOT NULL,
	[SupplierAddress] [nvarchar](100) NOT NULL,
	[Email] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK__Suppliers_SupplierId] PRIMARY KEY CLUSTERED 
(
	[SupplierId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Suppliers]  WITH CHECK ADD  CONSTRAINT [FK__Suppliers__CustomerId] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([CustomerId])
GO

ALTER TABLE [dbo].[Suppliers] CHECK CONSTRAINT [FK__Suppliers__CustomerId]
GO

--EmployeeInfo

CREATE TABLE [ref].[EmployeeInfo](
	[EmployeeInfoID] [int] NOT NULL,
	[EmployeeID] [int] NOT NULL,
	[PhoneNumber] [nvarchar](50) NULL,
	[FixedSalary] [float] NOT NULL,
	[EmployeeAddress] [nvarchar](100) NOT NULL,
	[IsWorker] [bit] NOT NULL,
 CONSTRAINT [PK__EmployeeInfo_EmployeeInfoId] PRIMARY KEY CLUSTERED 
(
	[EmployeeInfoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [ref].[EmployeeInfo]  WITH CHECK ADD  CONSTRAINT [FK__EmployeeInfo_EmployeeId] FOREIGN KEY([EmployeeID])
REFERENCES [workers].[Employees] ([EmployeeID])
GO

ALTER TABLE [ref].[EmployeeInfo] CHECK CONSTRAINT [FK__EmployeeInfo_EmployeeId]
GO

--SalesReturnInfo

CREATE TABLE [ref].[SalesReturnInfo](
	[ReturnId] [int] NOT NULL,
	[OrderId] [int] NOT NULL,
	[ReturnDate] [date] NOT NULL,
	[CusotmerReturnReason] [nvarchar](100) NOT NULL,
	[IsReturned] [bit] NOT NULL,
 CONSTRAINT [PK__SalesReturnInfo_ReturnId] PRIMARY KEY CLUSTERED 
(
	[ReturnId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [ref].[SalesReturnInfo]  WITH CHECK ADD  CONSTRAINT [FK__SalesReturnInfo_OrderId] FOREIGN KEY([OrderId])
REFERENCES [dbo].[Orders] ([OrderID])
GO

ALTER TABLE [ref].[SalesReturnInfo] CHECK CONSTRAINT [FK__SalesReturnInfo_OrderId]
GO

--Employees

CREATE TABLE [workers].[Employees](
	[EmployeeID] [int] NOT NULL,
	[PositionId] [int] NOT NULL,
	[FirstName] [varchar](50) NOT NULL,
	[MiddleName] [varchar](50) NULL,
	[LastName] [varchar](50) NOT NULL,
	[BirthDate] [date] NOT NULL,
	[Gender] [bit] NOT NULL,
 CONSTRAINT [PK__Employees_EmployeeId] PRIMARY KEY CLUSTERED 
(
	[EmployeeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [workers].[Employees]  WITH CHECK ADD  CONSTRAINT [FK__Employees__PositionId] FOREIGN KEY([PositionId])
REFERENCES [workers].[Positions] ([PositionID])
GO

ALTER TABLE [workers].[Employees] CHECK CONSTRAINT [FK__Employees__PositionId]
GO

ALTER TABLE [workers].[Employees]  WITH CHECK ADD  CONSTRAINT [constraint_birthDate] CHECK  ((datediff(year,[BirthDate],getdate())>=(18)))
GO

ALTER TABLE [workers].[Employees] CHECK CONSTRAINT [constraint_birthDate]
GO

--Positions

CREATE TABLE [workers].[Positions](
	[PositionID] [int] NOT NULL,
	[PositionName] [nvarchar](500) NOT NULL,
 CONSTRAINT [PK__Positions_PositionId] PRIMARY KEY CLUSTERED 
(
	[PositionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO