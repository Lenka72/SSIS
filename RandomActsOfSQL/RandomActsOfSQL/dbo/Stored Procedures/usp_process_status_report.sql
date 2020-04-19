


-- ================================================
-- Author:		Elaena Bakman		 
-- Create date: 02/21/2017
-- Description:	This used to be hard-coded in the 
-- report, but seems to not always behave as 
-- epected, so I figured I'd give this a shot. 
-- Update:		
-- ================================================
CREATE PROCEDURE [dbo].[usp_process_status_report]
AS
    BEGIN
        SET NOCOUNT ON;
        SELECT  S.name AS ProcessName
        FROM    msdb.dbo.sysjobs S WITH (NOLOCK)
        ORDER BY S.name;
    END;
