CREATE TABLE [dbo].[employee] (
    [EmployeeId] INT           IDENTITY (1, 1) NOT NULL,
    [NetworkId]  VARCHAR (25)  NOT NULL,
    [FirstName]  VARCHAR (50)  NULL,
    [LastName]   VARCHAR (50)  NULL,
    [Email]      VARCHAR (255) NULL
);

