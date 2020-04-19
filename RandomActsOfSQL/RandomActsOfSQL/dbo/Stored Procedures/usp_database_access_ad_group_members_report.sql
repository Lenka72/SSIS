

-- ================================================
-- Author:		Elaena Bakman - 131789		 
-- Create date: 09/21/2017
-- Description:	This stored procedure will drive a 
-- report that would allow audit to view the members 
-- of AD groups that have access to this database.
-- Update:		
-- ================================================
-- Type:		0 - Report Only
--				1 - Import New Version
-- ================================================

CREATE PROCEDURE [dbo].[usp_database_access_ad_group_members_report] (
        @Type INT = 0
       ,@VersionFilter BIGINT
       ,@UserId dtUserId = NULL)
AS
BEGIN
        SET NOCOUNT ON;
        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

        DECLARE @JobListTable dbo.job_list_table_type
               ,@ParameterListTable dbo.parameter_list_table_type
               ,@JobName VARCHAR(255)
               ,@Result INT;

        IF @Type = 1
        BEGIN
                SET @JobName = 'Get AD Members Audit';

                INSERT INTO @JobListTable (JobName)
                VALUES ('Get AD Members Audit');

                EXEC dbo.usp_run_job @JobListTable = @JobListTable
                                    ,@JobName = @JobName
                                    ,@ParameterListTable = @ParameterListTable
                                    ,@UserId = @UserId;
        END;

        SELECT      AGMA.ADGroupMembersAuditRecordId
                   ,AGMA.CreateDate
                   ,AGMA.UpdateDate
                   ,AGMA.UserId
                   ,AGMA.Version
                   ,AGMA.VersionComment
                   ,AGMA.GroupName
                   ,AGMA.AccountName
                   ,AGMA.Type
                   ,AGMA.Privilege
                   ,AGMA.MappedLoginName
        FROM        dbo.ad_group_members_audit AGMA
        WHERE       AGMA.Version = @VersionFilter
        ORDER BY    AGMA.GroupName
                   ,AGMA.MappedLoginName;
END;
