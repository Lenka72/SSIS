


-- ================================================
-- Author:		Elaena Bakman		 
-- Create date: 04/20/2017
-- Description:	This will pull the database access roles for audit.
-- Update:		131789 - E. Bakman 09/22/2017
-- ================================================
-- Run Type:
--		0 - Report Only
--		1 - Import New Version
-- =============================================

CREATE PROCEDURE [dbo].[usp_database_access_report] (
    @Type INT = 0
   ,@VersionFilter BIGINT
   ,@UserId dtUserId = 'system')
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
        SET @JobName = 'Get Access Audit';

        INSERT INTO @JobListTable (JobName)
        VALUES ('Get Access Audit');

        EXEC dbo.usp_run_job @JobListTable = @JobListTable
                            ,@JobName = @JobName
                            ,@ParameterListTable = @ParameterListTable
                            ,@UserId = @UserId;
    END;

    SELECT      DAA.CreateDate
               ,DAA.UpdateDate
               ,DAA.Version
               ,DAA.VersionComment
               ,DAA.LoginId
               ,DAA.DatabaseLoginName
               ,DAA.DatabaseLoginTypeDescription
               ,DAA.DatabaseLoginAuthenticationTypeDescription
               ,DAA.DatabaseLoginDefaultSchemaName
               ,DAA.ServerLoginName
               ,DAA.ServerLoginTypeDescription
               ,DAA.ServerLoginCreateDate
               ,DAA.ServerLoginModifyDate
               ,DAA.ServerLoginDefaultDatabaseName
               ,DAA.DatabaseRoleId
               ,DAA.DatabaseRoleName
               ,DAA.DatabaseRoleCreateDate
               ,DAA.DatabaseRoleModifyDate
               ,DAA.BuiltinDatabaseRole
               ,DAA.DatabasePermissionName
               ,DAA.DatabasePermission
			   ,DAA.SchemaName
			   ,DAA.SchemaPermissionName
			   ,DAA.SchemaPermission
               ,DAA.DatabasePermissionCount
    FROM        dbo.database_access_audit DAA WITH (NOLOCK)
    WHERE       DAA.Version = @VersionFilter
    ORDER BY    DAA.DatabaseLoginName;
END;
