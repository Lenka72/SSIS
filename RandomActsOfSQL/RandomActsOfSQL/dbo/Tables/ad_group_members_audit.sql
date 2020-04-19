CREATE TABLE [dbo].[ad_group_members_audit] (
    [ADGroupMembersAuditRecordId] BIGINT           IDENTITY (1, 1) NOT NULL,
    [CreateDate]                  DATETIME         CONSTRAINT [DF_ad_group_members_audit_CreateDate] DEFAULT (getdate()) NOT NULL,
    [UpdateDate]                  DATETIME         CONSTRAINT [DF_ad_group_members_audit_UpdateDate] DEFAULT (getdate()) NOT NULL,
    [UserId]                      [dbo].[dtUserId] CONSTRAINT [DF_ad_group_members_audit_UserId] DEFAULT (replace(suser_sname(),'THOR\','')) NOT NULL,
    [Version]                     BIGINT           NOT NULL,
    [VersionComment]              VARCHAR (1000)   NULL,
    [GroupName]                   VARCHAR (500)    NULL,
    [AccountName]                 VARCHAR (500)    NULL,
    [Type]                        VARCHAR (10)     NULL,
    [Privilege]                   VARCHAR (10)     NULL,
    [MappedLoginName]             VARCHAR (500)    NULL,
    CONSTRAINT [PK_ad_group_members_audit] PRIMARY KEY NONCLUSTERED ([ADGroupMembersAuditRecordId] ASC)
);

