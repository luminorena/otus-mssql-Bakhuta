use master
ALTER DATABASE VetShop SET SINGLE_USER WITH ROLLBACK IMMEDIATE
ALTER DATABASE VetShop SET ENABLE_BROKER
ALTER DATABASE VetShop SET MULTI_USER

--создать сообщение

USE VetShop
-- запрос
CREATE MESSAGE TYPE
[//VS/SB/RequestMessage]
VALIDATION=WELL_FORMED_XML;
-- ответ
CREATE MESSAGE TYPE
[//VS/SB/ReplyMessage]
VALIDATION=WELL_FORMED_XML; 

--контракт

CREATE CONTRACT [//VS/SB/Contract]
      ([//VS/SB/RequestMessage]
         SENT BY INITIATOR,
       [//VS/SB/ReplyMessage]
         SENT BY TARGET
      );
select * from Sales.CustomerPayments
select * from sales.Orders

-- поле, чтобы фиксировать получение данных из очереди
ALTER TABLE Sales.Orders
ADD OrdersConfirmedForProcessing DATETIME;

-- создание очереди и сервисов

CREATE QUEUE TargetOrdersQueue;

CREATE SERVICE [//VS/SB/TargetService]
       ON QUEUE TargetOrdersQueue
       ([//VS/SB/Contract]);


CREATE QUEUE InitiatorOrdersQueue;

CREATE SERVICE [//VS/SB/InitiatorService]
       ON QUEUE InitiatorOrdersQueue
       ([//VS/SB/Contract]);

-- процедура отправки сообщения в очередь - отправка заказов

DROP PROC IF EXISTS Sales.SendOrders;
GO

CREATE PROCEDURE Sales.SendOrders
	@OrderId INT
AS

BEGIN
	SET NOCOUNT ON;

--отправка сообщения на таргет
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER; 
	DECLARE @RequestMessage NVARCHAR(4000); 
	
	BEGIN TRAN 

--подготовка сообщения
	SELECT @RequestMessage = (select Orders.OrderId,CustomerId, Quantity, 
							  CostPerUnit, SaleDate, 
							  OrdersConfirmedForProcessing, PaymentId,
							  IsPayedSuccessfully
							  from sales.Orders Orders
							  join sales.CustomerPayments CustomerPayments on
							  Orders.OrderID = CustomerPayments.OrderId
							  where Orders.OrderID = @OrderId
							  FOR XML AUTO, root('RequestMessage')); 
--определяем сервис инициатора, таргет и контракт
	BEGIN DIALOG @InitDlgHandle
	FROM SERVICE
	[//VS/SB/InitiatorService]
	TO SERVICE
	'//VS/SB/TargetService'
	ON CONTRACT
	[//VS/SB/Contract]
	WITH ENCRYPTION=OFF; 

--Отправить сообщение
	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE
	[//VS/SB/RequestMessage]
	(@RequestMessage);
	COMMIT TRAN 
END
GO

--процедура получения сообщения
drop procedure if exists Sales.GetInvoicesWithParams
go

CREATE PROCEDURE Sales.GetInvoicesWithParams
AS
BEGIN

	DECLARE @TargetDlgHandle UNIQUEIDENTIFIER, 
			@Message NVARCHAR(4000), 
			@MessageType Sysname, 
			@ReplyMessage NVARCHAR(4000),
			@ReplyMessageName Sysname, 
			@OrderID INT,
			@xml XML; 
	
	BEGIN TRAN; 

--получить сообщение от инициатора
	RECEIVE TOP(1)
		@TargetDlgHandle = Conversation_Handle,
		@Message = Message_Body,
		@MessageType = Message_Type_Name
	FROM dbo.TargetOrdersQueue; 

	SELECT @Message;

	SET @xml = CAST(@Message AS XML);

	/*
	 Select 
		R.Iv.value('@OrderID', 'int') AS OrderID,
		R.Iv.value('@CustomerId', 'int') AS CustomerId,
		R.Iv.value('@Quantity', 'int') AS Quantity,
		R.Iv.value('@CostPerUnit', 'decimal(18,2)') AS 'CostPerUnit',
		R.Iv.value('@SaleDate', 'date') AS 'SaleDate',
		R.Iv.value('@PaymentId', 'int') AS 'PaymentId',
		R.Iv.value('@IsPayedSuccessfully', 'bit') AS 'IsPayedSuccessfully'
	 FROM @xml.nodes('/RequestMessage/Orders') as R(Iv)
	*/
	
	

	SELECT @OrderID = R.Iv.value('@OrderID','INT')
   FROM @xml.nodes('/RequestMessage/Orders') as R(Iv);
	 
	 IF EXISTS (SELECT * FROM sales.Orders WHERE OrderID = @OrderID)
	BEGIN
		UPDATE Sales.Orders
		SET OrdersConfirmedForProcessing = GETUTCDATE()
		WHERE OrderID = @OrderID;
	END;


	-- Confirm and Send a reply
	IF @MessageType=N'//VS/SB/RequestMessage'
	BEGIN
		SET @ReplyMessage =N'<ReplyMessage> Message received</ReplyMessage>'; 
	
		SEND ON CONVERSATION @TargetDlgHandle
		MESSAGE TYPE
		[//VS/SB/ReplyMessage]
		(@ReplyMessage);
		END CONVERSATION @TargetDlgHandle;
	END 
	
	SELECT @ReplyMessage AS SentReplyMessage; 

	COMMIT TRAN;
END

--получение подтверждения
go
drop procedure if exists Sales.ConfirmOrder
go
CREATE PROCEDURE Sales.ConfirmOrder
AS
BEGIN
	--Receiving Reply Message from the Target.	
	DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER,
			@ReplyReceivedMessage NVARCHAR(1000) 
	
	BEGIN TRAN; 

		RECEIVE TOP(1)
			@InitiatorReplyDlgHandle=Conversation_Handle
			,@ReplyReceivedMessage=Message_Body
		FROM dbo.InitiatorOrdersQueue; 
		
		END CONVERSATION @InitiatorReplyDlgHandle; 
		
		SELECT @ReplyReceivedMessage AS ReceivedRepliedMessage; 

	COMMIT TRAN; 
END

--активация очередей

GO
ALTER QUEUE [dbo].[InitiatorOrdersQueue] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF) 
	, ACTIVATION (   STATUS = ON ,
        PROCEDURE_NAME = Sales.ConfirmOrder, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER) ; 

GO
ALTER QUEUE [dbo].[TargetOrdersQueue] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF)
	, ACTIVATION (  STATUS = ON ,
        PROCEDURE_NAME = Sales.GetInvoicesWithParams, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER) ; 

GO
-- проверка
--отправляем OrderId = 1
select * from sales.Orders
where OrderID = 1

select Orders.OrderId,CustomerId, Quantity, 
							  CostPerUnit, SaleDate, 
							  OrdersConfirmedForProcessing, PaymentId,
							  IsPayedSuccessfully
							  from sales.Orders Orders
							  join sales.CustomerPayments CustomerPayments on
							  Orders.OrderID = CustomerPayments.OrderId
where Orders.OrderID = 1

EXEC Sales.SendOrders
	@orderId = 1

--смотрим очереди, сообщение будет в таргете
SELECT CAST(message_body AS XML),*
FROM dbo.TargetOrdersQueue;

SELECT CAST(message_body AS XML),*
FROM dbo.InitiatorOrdersQueue;

--проверка статуса диалога

SELECT conversation_handle, is_initiator, s.name as 'local service', 
far_service, sc.name 'contract', ce.state_desc
FROM sys.conversation_endpoints ce
LEFT JOIN sys.services s
ON ce.service_id = s.service_id
LEFT JOIN sys.service_contracts sc
ON ce.service_contract_id = sc.service_contract_id
ORDER BY conversation_handle;


--Target
EXEC Sales.GetInvoicesWithParams

--Initiator
EXEC Sales.ConfirmOrder

