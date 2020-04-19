

-- ================================================
-- Author:		Elaena Bakman - 2016 Upgrade		 
-- Create date: 04/13/2017
-- Description:	This report would allow users to view 
-- the hob history or current and prior executions 
-- based on the job name.  This would hopefully help 
-- WITH audit questions.
-- Update:		129585 - E. Bakman 08/04/2017
-- ================================================
-- Action:		1 - Run Job
--				2 - Run Job from Step
--				3 - Cancel Job
-- ================================================

CREATE PROCEDURE [dbo].[usp_job_history_report] (
        @JobName sysname = NULL
       ,@Action INT = NULL
       ,@StepName sysname = NULL
       ,@UserId dtUserId = NULL)
AS
BEGIN
        SET NOCOUNT ON;

        DECLARE @job_id UNIQUEIDENTIFIER
               ,@JobListTable dbo.job_list_table_type
               ,@ParameterListTable dbo.parameter_list_table_type
               ,@ErrorMessage VARCHAR(500)
               ,@Result INT;

        --======================== uncomment this for testing ==============
        --IF OBJECT_ID('tempdb..#scheduled_jobs') IS NOT NULL
        --    DROP TABLE #scheduled_jobs;
        --======================== uncomment this for testing ==============
        SELECT          DISTINCT SJ.job_id AS JobId
                                ,SJ.name AS JobName
        INTO            #scheduled_jobs
        FROM            msdb.dbo.sysjobs SJ
        INNER   JOIN    msdb.dbo.sysjobschedules SJS
        ON SJS.job_id = SJ.job_id;

        IF @Action IN (1, 2)
        BEGIN
                IF
                (SELECT COUNT(1)FROM #scheduled_jobs SJ WHERE   SJ.JobName = @JobName) = 0
                BEGIN
                        SET @ErrorMessage = 'Error: This process is only setup to run scheduled jobs!  Please use the appropriate interface to run all other Valuations jobs.';

                        RAISERROR(@ErrorMessage, 16, 1);

                        RETURN;
                END;

                INSERT INTO @JobListTable (JobName)
                VALUES
                (@JobName);

                --to make sure that we start from Step 1 unless the job is kicked off as "Run Job from Step", lets clear the Step Name if the "Run Job from Step" Action Type is not passed in.
                IF @Action != 2
                        SET @StepName = NULL;

                EXEC @Result = msdb.dbo.sp_start_job @job_name = @JobName
                                                    ,@step_name = @StepName;
        END;

        IF @Action = 3
        BEGIN
                EXEC @Result = msdb.dbo.sp_stop_job @job_name = @JobName;
                WAITFOR DELAY '00:00:01'; --hoping this would be enough to let the job stop and update the sysjobactivity table
        END;

        SET @job_id =
        (SELECT S.job_id FROM   msdb.dbo.sysjobs S WHERE S.name = @JobName);

        WITH RunStatus AS (SELECT   IQ.RunStatus
                                   ,IQ.RunStatusDescription
                           FROM     (VALUES
                                             (0, 'Failed')
                                            ,(1, 'Succeeded')
                                            ,(2, 'Retry')
                                            ,(3, 'Canceled')) IQ (RunStatus, RunStatusDescription) )
            ,JobsRunning AS (SELECT         JA.job_id AS JobId
                                           ,CAST(1 AS BIT) AS JobCurrentlyRunning
                             FROM           msdb.dbo.sysjobs SJ
                             INNER   JOIN   msdb.dbo.sysjobactivity JA
                             ON SJ.job_id = JA.job_id
                             WHERE          JA.start_execution_date IS NOT NULL
                                            AND JA.stop_execution_date IS NULL)
            ,JobOutcome AS (SELECT          SJH.instance_id AS InstanceId
                                           ,SJH.instance_id AS JobOutcomeInstanceId
                                           ,ISNULL( LEAD(SJH.instance_id) OVER (PARTITION BY SJH.job_id ORDER BY SJH.instance_id DESC), FR.FirstRunFirStep) AS PriorJopbOutcomeInstanceId
                                           ,SJH.job_id AS JobId
                                           ,SJ.name AS JobName
                                           ,1000 AS StepId
                                           ,'Job outcome' AS StepName
                                           ,SJH.sql_message_id AS MessageId
                                           ,SJH.message AS MessageName
                                           ,SJH.sql_severity AS ErrorSeverity
                                           ,RS.RunStatusDescription
                                           ,CALC.StartDateTime
                                           ,CONCAT(
                                                    RIGHT('0' + CAST(CALC.DurationDays AS VARCHAR(2)), 2), '.', RIGHT('0' + CAST(CALC.DurationHours AS VARCHAR(2)), 2), ':', RIGHT('0' + CAST(CALC.DurationMinutes AS VARCHAR(2)), 2), ':'
                                                   ,RIGHT('0' + CAST(CALC.DurationSeconds AS VARCHAR(2)), 2)) AS RunDuration
                                           ,SJH.operator_id_emailed
                                           ,SJH.operator_id_paged
                                           ,SJH.retries_attempted AS NumberOfRetries
                            FROM            msdb.dbo.sysjobhistory SJH
                            INNER   JOIN    msdb.dbo.sysjobs SJ
                            ON SJ.job_id = SJH.job_id
                            INNER   JOIN    RunStatus RS
                            ON RS.RunStatus = SJH.run_status
                            CROSS   APPLY   (SELECT     MIN(    SJH2.instance_id) AS FirstRunFirStep
                                             FROM       msdb.dbo.sysjobhistory SJH2 WITH (NOLOCK)
                                             WHERE      SJH2.job_id = SJH.job_id) FR
                            OUTER   APPLY   (SELECT dbo.fn_agent_datetime(SJH.run_date, SJH.run_time) AS StartDateTime
                                                   ,CASE
                                                            WHEN SJH.run_duration / 10000 > 24 THEN (SJH.run_duration / 10000) / 24
                                                            ELSE    0
                                                    END AS DurationDays
                                                   ,CASE
                                                            WHEN SJH.run_duration / 10000 > 24 THEN (SJH.run_duration / 10000) % 24
                                                            ELSE    SJH.run_duration / 10000
                                                    END AS DurationHours
                                                   ,SJH.run_duration / 100 % 100 AS DurationMinutes
                                                   ,SJH.run_duration % 100 AS DurationSeconds) CALC(StartDateTime, DurationDays, DurationHours, DurationMinutes, DurationSeconds)
                            WHERE           ISNULL( @job_id, SJ.job_id) = SJH.job_id
                                            AND SJH.step_name = '(Job outcome)')
            ,JobList AS (SELECT     JO.InstanceId
                                   ,JO.JobOutcomeInstanceId
                                   ,JO.PriorJopbOutcomeInstanceId
                                   ,JO.JobId
                                   ,JO.JobName
                                   ,JO.StepId
                                   ,JO.StepName
                                   ,'Job Outcome' AS StepType
                                   ,CONVERT(VARCHAR(500), NULL) AS SSISPackageName
                                   ,JO.MessageId
                                   ,JO.MessageName
                                   ,JO.ErrorSeverity
                                   ,JO.RunStatusDescription
                                   ,JO.StartDateTime
                                   ,JO.RunDuration
                                   ,JO.operator_id_emailed AS OperatorIdEmailed
                                   ,JO.operator_id_paged AS OperatorIdPaged
                                   ,JO.NumberOfRetries
                         FROM       JobOutcome JO
                         UNION
                         SELECT             SJH.instance_id AS InstanceId
                                           ,JO.JobOutcomeInstanceId
                                           ,JO.PriorJopbOutcomeInstanceId
                                           ,SJ.job_id AS JobId
                                           ,SJ.name AS JobName
                                           ,SJH.step_id AS StepId
                                           ,SJS.step_name AS StepName
                                           ,SJS.subsystem AS StepType
                                           ,NULLIF(LTRIM(  RTRIM(CALC7.PackageName)), '') AS SSISPackageName
                                           ,SJH.sql_message_id AS MessageId
                                           ,SJH.message AS MessageName
                                           ,SJH.sql_severity AS ErrorSeverity
                                           ,RS.RunStatusDescription
                                           ,CALC.StartDateTime
                                           ,CONCAT(
                                                    RIGHT('0' + CAST(CALC.DurationDays AS VARCHAR(2)), 2), '.', RIGHT('0' + CAST(CALC.DurationHours AS VARCHAR(2)), 2), ':', RIGHT('0' + CAST(CALC.DurationMinutes AS VARCHAR(2)), 2), ':'
                                                   ,RIGHT('0' + CAST(CALC.DurationSeconds AS VARCHAR(2)), 2)) AS RunDuration
                                           ,SJH.operator_id_emailed
                                           ,SJH.operator_id_paged
                                           ,SJH.retries_attempted AS NumberOfRetries
                         FROM               msdb.dbo.sysjobs SJ
                         LEFT    OUTER JOIN msdb.dbo.sysjobsteps SJS
                         ON SJS.job_id = SJ.job_id
                         LEFT    OUTER JOIN msdb.dbo.sysjobhistory SJH
                         ON SJH.job_id = SJ.job_id
                            AND SJH.step_id = SJS.step_id
                         INNER   JOIN       RunStatus RS
                         ON RS.RunStatus = SJH.run_status
                         LEFT    OUTER JOIN JobOutcome JO
                         ON JO.JobId = SJH.job_id
                         OUTER   APPLY      (SELECT dbo.fn_agent_datetime(SJH.run_date, SJH.run_time) AS StartDateTime
                                                   ,CASE
                                                            WHEN SJH.run_duration / 10000 > 24 THEN (SJH.run_duration / 10000) / 24
                                                            ELSE    0
                                                    END AS DurationDays
                                                   ,CASE
                                                            WHEN SJH.run_duration / 10000 > 24 THEN (SJH.run_duration / 10000) % 24
                                                            ELSE    SJH.run_duration / 10000
                                                    END AS DurationHours
                                                   ,SJH.run_duration / 100 % 100 AS DurationMinutes
                                                   ,SJH.run_duration % 100 AS DurationSeconds) CALC(StartDateTime, DurationDays, DurationHours, DurationMinutes, DurationSeconds)
                         OUTER   APPLY      (SELECT IIF(SJS.subsystem = 'SSIS', CHARINDEX('dtsx', SJS.command) + 4, 0)) CALC4(EndOfStringLocation)
                         OUTER   APPLY      (SELECT IIF(SJS.subsystem = 'SSIS', REVERSE(LEFT(SJS.command, CALC4.EndOfStringLocation - 1)), '') AS StarOfString) CALC5(StartOfString)
                         OUTER   APPLY      (SELECT IIF(SJS.subsystem = 'SSIS', CHARINDEX('\', CALC5.StartOfString), 0) AS EndOfString) CALC6(StartOfStringLocation)
                         OUTER   APPLY      (SELECT IIF(SJS.subsystem = 'SSIS', REVERSE(LEFT(CALC5.StartOfString, CALC6.StartOfStringLocation - 1)), '') AS FinalString) CALC7(PackageName)
                         WHERE              ISNULL( @job_id, SJ.job_id) = SJ.job_id
                                            AND SJH.instance_id BETWEEN JO.PriorJopbOutcomeInstanceId AND JO.JobOutcomeInstanceId)
        SELECT              JL.InstanceId
                           ,JL.JobOutcomeInstanceId
                           ,JL.PriorJopbOutcomeInstanceId
                           ,JL.JobId
                           ,JL.JobName
                           ,JL.StepId
                           ,JL.StepName
                           ,JL.StepType
                           ,JL.SSISPackageName
                           ,JL.MessageId
                           ,JL.MessageName
                           ,JL.ErrorSeverity
                           ,JL.RunStatusDescription
                           ,JL.StartDateTime
                           ,JL.RunDuration
                           ,JL.OperatorIdEmailed
                           ,JL.OperatorIdPaged
                           ,JL.NumberOfRetries
                           ,ROW_NUMBER() OVER (PARTITION BY JL.JobName ORDER BY JL.JobOutcomeInstanceId DESC) AS GroupByJob
                           ,ROW_NUMBER() OVER (PARTITION BY JL.JobName
                                                           ,JL.JobOutcomeInstanceId
                                               ORDER BY JL.JobOutcomeInstanceId) AS GroupByInstance
                           ,ISNULL( JR.JobCurrentlyRunning, 0) AS JobCurrentlyRunning
                           ,CAST(IIF(    SJ.JobId IS NOT NULL, 1, 0) AS BIT) AS IsScheduledJob
                           ,SAE.FolderName
                           ,SAE.ProjectName
                           ,SAE.PackageName
        FROM                JobList JL
        LEFT    OUTER JOIN  JobsRunning JR
        ON JR.JobId = JL.JobId
        LEFT    OUTER JOIN  #scheduled_jobs SJ
        ON SJ.JobId = JL.JobId
        OUTER   APPLY       (SELECT     DISTINCT E.folder_name AS FolderName
                                                ,E.project_name AS ProjectName
                                                ,E.package_name AS PackageName
                             FROM       SSISDB.catalog.executions E
                             WHERE      E.package_name = JL.SSISPackageName) SAE
        ORDER BY            JL.JobName
                           ,JL.JobOutcomeInstanceId DESC
                           ,JL.StartDateTime DESC
                           ,JL.StepId DESC;
END;
