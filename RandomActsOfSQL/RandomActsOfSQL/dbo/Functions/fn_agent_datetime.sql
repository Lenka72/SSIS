--   =============================================
--   Author:        Elaena Bakman -  2016 Upgrade
--   Create date: 03/21/2017
--   Description:    This function will calculate and return the Mod Bal Cange value.
--   Example:
--   SELECT TOP 1  S.run_date, S.run_time, dbo.fn_agent_datetime(S.run_date, S.run_time) FROM msdb.dbo.sysjobhistory S
--   =============================================
CREATE FUNCTION [dbo].[fn_agent_datetime] (@Date INT, @Time INT)
RETURNS DATETIME
AS    
BEGIN        
	RETURN  (  CAST(STR(@Date, 8,   0)  AS   DATETIME) 
					+ CAST(STUFF(STUFF(RIGHT('000000' +  CAST (@Time AS   VARCHAR(6)), 6), 5,   0,   ':'), 3,   0,   ':') AS   DATETIME)  );    
END;
