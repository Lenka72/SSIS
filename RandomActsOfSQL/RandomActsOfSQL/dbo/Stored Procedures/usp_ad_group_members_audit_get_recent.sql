
-- ================================================
-- Author:		Elaena Bakman  
-- Create date: 09/21/2017
-- Description:	This stored procedure will be run 
-- by a job to grab the most recent snapshot of 
-- the AD Group Members for this database.
-- Update:		
-- ================================================

CREATE PROCEDURE dbo.usp_ad_group_members_audit_get_recent
AS
BEGIN
        SET NOCOUNT ON;

        DECLARE @Version BIGINT
               ,@UserId dtUserId;

        SET @UserId = dbo.fn_get_process_started_by_uerid('Valuation - Get AD Members Audit');
        SET @Version = CONVERT(BIGINT, REPLACE(REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GETDATE(), 121), ':', ''), '-', ''), ' ', ''), '.', ''));

        --get data using sys.xp_logininfo
        CREATE TABLE #ad_group_members (AccountName VARCHAR(500)
                                       ,Type VARCHAR(10)
                                       ,Privilege VARCHAR(10)
                                       ,MappedLoginName VARCHAR(500)
                                       ,PermissionPath VARCHAR(500));

        DECLARE @GroupName sysname
               ,@SQL NVARCHAR(MAX);

        DECLARE GorupCursor CURSOR FAST_FORWARD LOCAL FOR
        SELECT  DP.name
        FROM    sys.database_principals DP
        WHERE   DP.type = 'G';

        OPEN GorupCursor;

        FETCH NEXT FROM GorupCursor
        INTO    @GroupName;

        WHILE @@FETCH_STATUS = 0
        BEGIN
                SET @SQL = CONCAT('EXEC sys.xp_logininfo ''', @GroupName, ''', ''members''');

                INSERT INTO #ad_group_members
                (AccountName
                ,Type
                ,Privilege
                ,MappedLoginName
                ,PermissionPath)
                EXECUTE sys.sp_executesql @SQL;

                FETCH NEXT FROM GorupCursor
                INTO    @GroupName;
        END;

        CLOSE GorupCursor;
        DEALLOCATE GorupCursor;

        WITH OverallListOfGroups AS (SELECT     DP.name AS GroupName
                                     FROM       sys.database_principals DP
                                     WHERE      DP.type = 'G')
        INSERT INTO dbo.ad_group_members_audit
        (UserId
        ,Version
        ,GroupName
        ,AccountName
        ,Type
        ,Privilege
        ,MappedLoginName)
        SELECT              @UserId
                           ,@Version
                           ,OLG.GroupName
                           ,ISNULL( AGM.AccountName, 'None') AS AccountName
                           ,ISNULL( AGM.Type, 'n/a') AS Type
                           ,ISNULL( AGM.Privilege, 'n/a') AS Privilege
                           ,ISNULL( AGM.MappedLoginName, 'None') AS MappedLoginName
        FROM                OverallListOfGroups OLG
        LEFT    OUTER JOIN  #ad_group_members AGM
        ON AGM.PermissionPath = OLG.GroupName;
END;
