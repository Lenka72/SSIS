
-- =============================================
-- Author:		Elaena Bakman
-- Create date: 08/31/2018
-- Description:	This will provide the failed job 
-- status for the User Notification step
-- Updates:
-- =============================================

CREATE FUNCTION dbo.fn_get_job_failed_error_message (@JobName VARCHAR(128) = NULL)
RETURNS VARCHAR(MAX)
AS
BEGIN
        DECLARE @ErrorMessage VARCHAR(MAX);

        SELECT          @ErrorMessage = CONCAT( 'Step Id: ', CAST(JH.step_id AS VARCHAR(15)), ' Step Name: ', JH.step_name, CHAR(13), 'Error: ', JH.message)
        FROM            msdb.dbo.sysjobs J
        INNER   JOIN    msdb.dbo.sysjobactivity JA
        ON JA.job_id = J.job_id
        INNER   JOIN    msdb.dbo.sysjobhistory JH
        ON JH.job_id = J.job_id
           AND  dbo.fn_agent_datetime(JH.run_date, JH.run_time) >= JA.start_execution_date
        WHERE           J.name = @JobName
                        AND JH.run_status = 0;

        RETURN @ErrorMessage;
END;
