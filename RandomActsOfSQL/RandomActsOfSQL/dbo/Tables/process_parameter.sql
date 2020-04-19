CREATE TABLE [dbo].[process_parameter] (
    [ProcessParameterId] INT           IDENTITY (1, 1) NOT NULL,
    [ProcessId]          INT           NOT NULL,
    [ParameterName]      VARCHAR (50)  NOT NULL,
    [ParameterValue]     VARCHAR (255) NOT NULL,
    CONSTRAINT [PK_process_parameter] PRIMARY KEY CLUSTERED ([ProcessParameterId] ASC),
    CONSTRAINT [FK_process_parameter_process] FOREIGN KEY ([ProcessId]) REFERENCES [dbo].[process] ([ProcessId]) ON DELETE CASCADE
);

