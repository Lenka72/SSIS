CREATE TABLE [dbo].[People_IsNotPermittedToLogon] (
    [CreateDateTime]          DATETIME        NOT NULL,
    [FullName]                NVARCHAR (50)   NOT NULL,
    [PreferredName]           NVARCHAR (50)   NOT NULL,
    [IsPermittedToLogon]      BIT             NOT NULL,
    [LogonName]               NVARCHAR (50)   NULL,
    [IsExternalLogonProvider] BIT             NOT NULL,
    [HashedPassword]          VARBINARY (MAX) NULL,
    [IsSystemUser]            BIT             NOT NULL,
    [IsEmployee]              BIT             NOT NULL,
    [IsSalesperson]           BIT             NOT NULL,
    [UserPreferences]         NVARCHAR (MAX)  NULL,
    [PhoneNumber]             NVARCHAR (20)   NULL,
    [FaxNumber]               NVARCHAR (20)   NULL,
    [EmailAddress]            NVARCHAR (256)  NULL,
    [Photo]                   VARBINARY (MAX) NULL,
    [CustomFields]            NVARCHAR (MAX)  NULL,
    [LastEditedBy]            INT             NOT NULL
);

