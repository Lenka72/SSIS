CREATE TABLE [dbo].[process] (
    [ProcessId]        INT             IDENTITY (1, 1) NOT NULL,
    [ProcessName]      VARCHAR (150)   NOT NULL,
    [ProcessStarted]   DATETIME        CONSTRAINT [DF_process_ProcessStarted] DEFAULT (getdate()) NOT NULL,
    [ProcessCompleted] DATETIME        NULL,
    [UserId]           VARCHAR (25)    NULL,
    [Status]           VARCHAR (10)    NULL,
    [ErrorMessage]     NVARCHAR (4000) NULL,
    [Scheduled]        BIT             NULL,
    CONSTRAINT [PK_process] PRIMARY KEY CLUSTERED ([ProcessId] ASC)
);

