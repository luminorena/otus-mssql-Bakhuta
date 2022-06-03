ALTER DATABASE VetShop
ADD FILEGROUP VetShop_fs CONTAINS FILESTREAM

ALTER DATABASE VetShop
 ADD FILE
 (NAME = N'VetShop_1',
	FILENAME = N'C:\myFTCatalogs2',
	--SIZE = 10MB,
	MAXSIZE = 20MB
	--FILEGROWTH = 1MB
)
 TO FILEGROUP VetShop_fs
GO

create table ref.Documents
(
Guid uniqueidentifier rowguidcol not null unique,
DocumentId integer unique,
FileId varbinary(max) filestream
)
filestream_on VetShop_fs

insert into ref.Documents
select newid(), 1, *
from openrowset(bulk 'D:\MSSQL Developer\fotos for fileStream Otus\ветпрепараты.jpg', single_blob) as import

insert into ref.Documents
select newid(), 2, *
from openrowset(bulk 'D:\MSSQL Developer\fotos for fileStream Otus\предпринимательство.jpg', single_blob) 
as import

select * from ref.Documents

--добавить другую таблицу

create table ref.DocumentNames
(DocumentNameId int not null,
Name nvarchar(max) not null,
RespinsiblePersonPosition nvarchar(250) not null
)
ALTER TABLE ref.DocumentNames
   ADD CONSTRAINT PK_DocumentNameId PRIMARY KEY CLUSTERED (DocumentNameId);

insert into ref.DocumentNames (DocumentNameId, [Name], RespinsiblePersonPosition)
values (1, N'Лицензия на продажу ветеринарных препаратов',1),
(2, N'Лицензия на осуществление предпринимательской деятельности', 7)

--сделать FK в таблице FileStream
alter table ref.Documents
add constraint Document_FK FOREIGN KEY (DocumentId) references ref.DocumentNames (DocumentNameId)

EXEC sp_rename 'ref.DocumentNames.RespinsiblePersonPosition', 'ResponsiblePersonPosition', 'COLUMN';

select * from ref.DocumentNames

