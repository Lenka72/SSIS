

-- ================================================
-- Author:		Elaena Bakman		 
-- Create date: 07/19/2018
-- Description:	Use this stored procedure to
-- identify missing indexes
-- Update:		
-- ================================================

CREATE PROCEDURE [dbo].[usp_missing_indexes_report] (
        @Top INT = 25
       ,@UserId dtUserId)
AS
BEGIN
        SET NOCOUNT ON;

        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

        DECLARE @Result INT;

		IF @Top IS NULL	
			SET @Top = 25; --don't know why, but the default it not working, so I had to add this.


        SELECT          TOP (@Top)  MID.database_id AS DatabaseID
                                   ,DB_NAME(  MID.database_id) AS DatabaseName
                                   ,MIGS.avg_user_impact * (MIGS.user_seeks + MIGS.user_scans) AS AverageEstimatedImpact
                                   ,MIGS.last_user_seek AS LastUserSeek
                                   ,OBJECT_NAME(MID.object_id, MID.database_id) AS TableName
                                   ,'CREATE INDEX [IX_' + OBJECT_NAME(MID.object_id, MID.database_id) + '_' + REPLACE(REPLACE(REPLACE(ISNULL(MID.equality_columns, ''), ', ', '_'), '[', ''), ']', '')
                                    + CASE
                                              WHEN MID.equality_columns IS NOT NULL
                                                   AND   MID.inequality_columns IS NOT NULL THEN '_'
                                              ELSE    ''
                                      END + REPLACE(REPLACE(REPLACE(ISNULL(MID.inequality_columns, ''), ', ', '_'), '[', ''), ']', '') + ']' + ' ON ' + MID.statement + ' (' + ISNULL( MID.equality_columns, '')
                                    + CASE
                                              WHEN MID.equality_columns IS NOT NULL
                                                   AND   MID.inequality_columns IS NOT NULL THEN ','
                                              ELSE    ''
                                      END + ISNULL( MID.inequality_columns, '') + ')' + ISNULL( ' INCLUDE (' + MID.included_columns + ')', '') AS CreateStatement
        FROM            sys.dm_db_missing_index_groups MIG
        INNER   JOIN    sys.dm_db_missing_index_group_stats MIGS
        ON MIGS.group_handle = MIG.index_group_handle
        INNER   JOIN    sys.dm_db_missing_index_details MID
        ON MIG.index_handle = MID.index_handle
        WHERE           MID.database_id = DB_ID(  'RandomActsOfSQL') OR MID.database_id = DB_ID('WideWorldImporters')
        ORDER BY        AverageEstimatedImpact DESC;
END;
