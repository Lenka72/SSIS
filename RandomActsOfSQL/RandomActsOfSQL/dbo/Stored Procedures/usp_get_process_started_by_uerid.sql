




-- =============================================
-- Author:		Elaena Bakman
-- Create date: 04/27/2015
-- Description:	This stored proc will pull the 
-- UserId of the user running the most recent process.
-- The @ProcessList should contain all items for
-- a process.  Example: 'Valuation - LAR Import Process, Valuation - LAR Import Process with Extracts'.
-- Both of the above items run the lar, so in some cases
-- you may want to look at both, in others you know 
-- the specific process (like from a job, you know what job is running).
-- Updates:		
-- =============================================
CREATE PROCEDURE dbo.usp_get_process_started_by_uerid (
        @ProcessList VARCHAR(MAX))
AS
BEGIN
        SET NOCOUNT ON;
        DECLARE @MaxProcessId INT;

        SELECT  @MaxProcessId = MAX(ProcessId)
        FROM    dbo.process
        WHERE   ProcessName IN
                        (SELECT Value FROM      dbo.fn_split(@ProcessList, ',') )
                AND     ProcessCompleted IS NULL;
        WITH CurrentProcessUserID AS (SELECT    REPLACE(UserId, 'PNMAC\', '') AS UserId
                                      FROM      dbo.process
                                      WHERE     ProcessId = @MaxProcessId)
        SELECT  COALESCE(R.UserId, REPLACE(SUSER_SNAME(), 'PNMAC\', ''), 'system') AS UserID
        FROM
                (SELECT 1 AS Fake)                                             F
        OUTER   APPLY
                (SELECT CurrentProcessUserID.UserId FROM CurrentProcessUserID) R;
END;




