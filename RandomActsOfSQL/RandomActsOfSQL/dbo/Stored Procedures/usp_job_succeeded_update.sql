



-- =============================================
-- Author:		Elaena Bakman
-- Create date: 12/02/2014
-- Description:	Update the Process table with 
-- "Succeeded" step in the Valuation jobs
-- Updates:		2016 Upgrade
-- =============================================
CREATE PROCEDURE dbo.usp_job_succeeded_update (
        @ProcessName VARCHAR(150))
AS
BEGIN
        SET NOCOUNT ON;
        WITH MostRecent AS (SELECT      ProcessId
                                       ,ProcessCompleted
                                       ,Status
                                       ,ROW_NUMBER() OVER (ORDER BY ProcessStarted DESC) AS Priority
                            FROM        dbo.process WITH (NOLOCK)
                            WHERE       ProcessCompleted IS NULL
                                        AND     ProcessName = @ProcessName)
        UPDATE  MostRecent
        SET     MostRecent.ProcessCompleted = GETDATE ()
               ,MostRecent.Status = 'Succeeded'
        WHERE   MostRecent.Priority = 1;
END;



