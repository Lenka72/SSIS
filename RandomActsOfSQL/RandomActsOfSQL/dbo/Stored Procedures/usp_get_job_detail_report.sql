

-- ================================================
-- Author:		Elaena Bakman - 131789		 
-- Create date: 09/18/2017
-- Description:	This stored procedure will drive 
-- the "jobs" report.  I don't have a name for it yet.
-- Update:		
-- ================================================

CREATE PROCEDURE [dbo].[usp_get_job_detail_report] (
        @JobName NVARCHAR(4000) = NULL
       ,@CategoryId INT = NULL
       ,@MainDatabaseName VARCHAR(255) = NULL
	   ,@UserId dtUserId = NULL)
AS
BEGIN
        SET NOCOUNT ON;
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

        DECLARE @JobId UNIQUEIDENTIFIER
		,@Result INT;

        CREATE TABLE #flags (
                Value INT
               ,Description VARCHAR(150));

        INSERT INTO #flags
        (Value
        ,Description)
        VALUES
        (0, 'Overwrite output file')
       ,(2, 'Append to output file')
       ,(4, 'Write Transact-SQL job step output to step history')
       ,(8, 'Write log to table (overwrite existing history)')
       ,(16, 'Write log to table (append to existing history)')
       ,(32, 'Write all output to job history')
       ,(64, 'Create a Windows event to use as a signal for the Cmd jobstep to abort');

        CREATE TABLE #fail_action (
                Value INT
               ,Description VARCHAR(150));

        INSERT INTO #fail_action
        (Value
        ,Description)
        VALUES
        (1, 'Quit with success')
       ,(2, 'Quit with failure')
       ,(3, 'Go to next step')
       ,(4, 'Go to step on_success_step_id');

        CREATE TABLE #success_action (
                Value INT
               ,Description VARCHAR(150));

        INSERT INTO #success_action
        (Value
        ,Description)
        VALUES
        (1, 'Quit with success')
       ,(2, 'Quit with failure')
       ,(3, 'Go to next step')
       ,(4, 'Go to step on_fail_step_id');

        CREATE TABLE #sp_help_jobstep (
                step_id INT NULL
               ,step_name NVARCHAR(128) NULL
               ,subsystem NVARCHAR(128) COLLATE Latin1_General_CI_AS NULL
               ,command NVARCHAR(MAX) NULL
               ,flags INT NULL
               ,cmdexec_success_code INT NULL
               ,on_success_action TINYINT NULL
               ,on_success_step_id INT NULL
               ,on_fail_action TINYINT NULL
               ,on_fail_step_id INT NULL
               ,server NVARCHAR(128) NULL
               ,database_name sysname NULL
               ,database_user_name sysname NULL
               ,retry_attempts INT NULL
               ,retry_interval INT NULL
               ,os_run_priority INT NULL
               ,output_file_name NVARCHAR(300) NULL
               ,last_run_outcome INT NULL
               ,last_run_duration INT NULL
               ,last_run_retries INT NULL
               ,last_run_date INT NULL
               ,last_run_time INT NULL
               ,proxy_id INT NULL
               ,job_id UNIQUEIDENTIFIER NULL
               ,job_main_database_name sysname NULL);

        DECLARE get_jobs CURSOR LOCAL FAST_FORWARD
        FOR(
        SELECT  SJV.job_id AS JobID
        FROM    msdb.dbo.sysjobs_view AS SJV
        WHERE
                ((@CategoryId IS NULL
                  AND   @JobName IS NULL
                  AND   SJV.name LIKE 'Valuation%')
                 OR
                 (@JobName IS NULL
                  AND   SJV.category_id = @CategoryId)
                 OR
                    (@CategoryId IS NULL
                     AND    SJV.name = @JobName)));

        OPEN get_jobs;

        FETCH get_jobs
        INTO    @JobId;

        WHILE @@fetch_status >= 0
        BEGIN
                INSERT INTO #sp_help_jobstep
                (step_id
                ,step_name
                ,subsystem
                ,command
                ,flags
                ,cmdexec_success_code
                ,on_success_action
                ,on_success_step_id
                ,on_fail_action
                ,on_fail_step_id
                ,server
                ,database_name
                ,database_user_name
                ,retry_attempts
                ,retry_interval
                ,os_run_priority
                ,output_file_name
                ,last_run_outcome
                ,last_run_duration
                ,last_run_retries
                ,last_run_date
                ,last_run_time
                ,proxy_id)
                EXEC msdb.dbo.sp_help_jobstep @job_id = @JobId;

                UPDATE  #sp_help_jobstep
                SET     job_id = @JobId
                WHERE   job_id IS NULL;

                FETCH get_jobs
                INTO    @JobId;
        END;

        CLOSE get_jobs;
        DEALLOCATE get_jobs;

        WITH GetMainJobDatabase AS (SELECT  SHJ.database_name
                                           ,SHJ.job_main_database_name
                                           ,MAX(    CASE
                                                            WHEN SHJ.subsystem = 'TSQL'
                                                                 AND SHJ.database_name NOT IN ('msdb', 'master') THEN SHJ.database_name
                                                            WHEN SHJ.subsystem = 'SSIS' THEN NULL
                                                    END) OVER (PARTITION BY SHJ.job_id) AS new_job_main_database_name
                                    FROM    #sp_help_jobstep SHJ)
        UPDATE  GetMainJobDatabase
        SET     GetMainJobDatabase.job_main_database_name = ISNULL(GetMainJobDatabase.new_job_main_database_name, GetMainJobDatabase.database_name);

        CREATE TABLE #sp_help_proxy (
                proxy_id INT NULL
               ,name NVARCHAR(300) NULL
               ,credential_identity NVARCHAR(300) NULL
               ,enabled TINYINT NULL
               ,description NVARCHAR(MAX) NULL
               ,user_sid BINARY(200) NULL
               ,credential_id INT NULL
               ,credential_identity_exists INT NULL);

        INSERT INTO #sp_help_proxy
        (proxy_id
        ,name
        ,credential_identity
        ,enabled
        ,description
        ,user_sid
        ,credential_id
        ,credential_identity_exists)
        EXEC msdb.dbo.sp_help_proxy;

        SELECT      SJV.name AS JobName
                   ,SJV.job_id AS JobId
                   ,SHJS.step_id AS StepId
                   ,SHJS.step_name AS StepName
                   ,SHJS.command AS Command
                   ,CALC4.PackageName
                   ,SHJS.cmdexec_success_code AS CommandExecutionSuccessCode
                   ,SHJS.database_name AS DatabaseName
                   ,SHJS.database_user_name AS DatabaseUserName
                   ,SHJS.job_main_database_name AS JobLevelMainDatabaseName
                   ,F.Description AS JobStepFlags
                   ,SHJS.last_run_duration AS LastRunDuration
                    --,SHJS.last_run_outcome AS LastRunOutcome
                   ,CASE
                            WHEN SHJS.last_run_outcome = 0 THEN 'Failed'
                            WHEN SHJS.last_run_outcome = 1 THEN 'Succeeded'
                            WHEN SHJS.last_run_outcome = 2 THEN 'Retry'
                            WHEN SHJS.last_run_outcome = 3 THEN 'Canceled'
                            WHEN SHJS.last_run_outcome = 5 THEN 'Unknown'
                    END AS LastRunOutcome
                   ,SHJS.last_run_retries AS LastRunRetries
                   ,RTRIM(REPLACE(REPLACE(FA.Description, 'on_fail_step_id', ''), 'on_success_step_id', '')) AS OnFailAction
                   ,SHJS.on_fail_step_id AS OnFailStep
                   ,RTRIM(REPLACE(REPLACE(SA.Description, 'on_success_step_id', ''), 'on_fail_step_id', '')) AS OnSuccessAction
                   ,SHJS.on_success_step_id AS OnSuccessStep
                   ,SHJS.os_run_priority AS OSRunPriority
                   ,ISNULL( SHJS.output_file_name, N'') AS OutputFileName
                   ,SHJS.retry_attempts AS RetryAttempts
                   ,SHJS.retry_interval AS RetryInterval
                   ,ISNULL( SHJS.server, N'') AS Server
                   ,CASE LOWER(  SHJS.subsystem)
                            WHEN 'tsql' THEN 1
                            WHEN 'activescripting' THEN 2
                            WHEN 'cmdexec' THEN 3
                            WHEN 'snapshot' THEN 4
                            WHEN 'logreader' THEN 5
                            WHEN 'distribution' THEN 6
                            WHEN 'merge' THEN 7
                            WHEN 'queuereader' THEN 8
                            WHEN 'analysisquery' THEN 9
                            WHEN 'analysiscommand' THEN 10
                            WHEN 'dts' THEN 11
                            WHEN 'ssis' THEN 11
                            WHEN 'powershell' THEN 12
                            ELSE    0
                    END AS SubSystemCode
                   ,SHJS.subsystem AS SubSystem
                   ,SHP.name AS ProxyName
                   ,SHJS.last_run_date AS LastRunDateInt
                   ,SHJS.last_run_time AS LastRunTimeInt
                   ,dbo.fn_agent_datetime(NULLIF(SHJS.last_run_date, 0), NULLIF(SHJS.last_run_time, 0)) AS LastRunDateTime
                   ,REPLACE(REPLACE(SC.name, '[', ''), ']', '') AS JobCategoryName
        FROM        msdb.dbo.sysjobs_view AS SJV
        INNER   JOIN #sp_help_jobstep AS SHJS
        ON SHJS.job_id = SJV.job_id
        INNER   JOIN msdb.dbo.syscategories SC
        ON SC.category_id = SJV.category_id
        LEFT    OUTER JOIN #sp_help_proxy AS SHP
        ON SHP.proxy_id = SHJS.proxy_id
        INNER   JOIN #flags F
        ON SHJS.flags = F.Value
        INNER   JOIN #fail_action FA
        ON FA.Value = SHJS.on_fail_action
        INNER   JOIN #success_action SA
        ON SA.Value = SHJS.on_success_action
        OUTER   APPLY (SELECT   IIF(SHJS.subsystem = 'SSIS', CHARINDEX('dtsx', SHJS.command) + 4, 0)) CALC1(EndOfStringLocation)
        OUTER   APPLY (SELECT   IIF(SHJS.subsystem = 'SSIS', REVERSE(LEFT(SHJS.command, IIF(CALC1.EndOfStringLocation = 0, 0, CALC1.EndOfStringLocation - 1))), '') AS StarOfString) CALC2(StartOfString)
        OUTER   APPLY (SELECT   IIF(SHJS.subsystem = 'SSIS', CHARINDEX('\', CALC2.StartOfString), 0) AS EndOfString) CALC3(StartOfStringLocation)
        OUTER   APPLY (SELECT   IIF(SHJS.subsystem = 'SSIS', REVERSE(LEFT(CALC2.StartOfString, IIF(CALC3.StartOfStringLocation = 0, 0, CALC3.StartOfStringLocation - 1))), '') AS FinalString) CALC4(PackageName)
        WHERE
                    (@JobName IS NULL
                     OR         @JobName IS NOT NULL
                                AND SJV.name = @JobName)
                    AND
                    (@CategoryId IS NULL
                     OR         @CategoryId IS NOT NULL
                                AND SC.category_id = @CategoryId)
                    AND
                    (@MainDatabaseName IS NULL
                     OR         @MainDatabaseName IS NOT NULL
                                AND SHJS.job_main_database_name = @MainDatabaseName)
        ORDER BY    SJV.name
                   ,SHJS.step_id ASC;
END;
