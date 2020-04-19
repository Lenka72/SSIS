

-- ================================================
-- Author:		Elaena Bakman		 
-- Create date: 07/19/2018
-- Description:	This stored procedure will help us
-- identify unused indexes.
-- Update:		
-- ================================================

CREATE PROCEDURE [dbo].[usp_unused_indexes_report] (
        @UserId dtUserId)
AS
BEGIN
        SET NOCOUNT ON;

        DECLARE @Result INT;

        SELECT          O.name AS ObjectName
                       ,I.name AS IndexName
                       ,I.index_id AS IndexID
                       ,DU.user_seeks AS UserSeek
                       ,DU.user_scans AS UserScans
                       ,DU.user_lookups AS UserLookups
                       ,DU.user_updates AS UserUpdates
                       ,P.TableRows
                       ,'IF EXISTS ( SELECT 1 FROM sys.indexes I WHERE I.object_id = OBJECT_ID(''' + OBJECT_NAME(DU.object_id) + ''') AND I.name = ''' + I.name + ''' )' AS IfExistsStatement
                       ,'DROP INDEX ' + QUOTENAME(I.name) + ' ON ' + QUOTENAME(S.name) + '.' + QUOTENAME(OBJECT_NAME(DU.object_id)) AS DropStatement
        FROM            sys.dm_db_index_usage_stats DU
        INNER   JOIN    sys.indexes I
        ON I.index_id = DU.index_id
           AND  DU.object_id = I.object_id
        INNER   JOIN    sys.objects O
        ON DU.object_id = O.object_id
        INNER   JOIN    sys.schemas S
        ON O.schema_id = S.schema_id
        INNER   JOIN    (SELECT     SUM(    P.rows) AS TableRows
                                   ,P.index_id
                                   ,P.object_id
                         FROM       sys.partitions P
                         GROUP BY   P.index_id
                                   ,P.object_id) P
        ON P.index_id = DU.index_id
           AND  DU.object_id = P.object_id
        WHERE           OBJECTPROPERTY(DU.object_id, 'IsUserTable') = 1
                        AND (DU.database_id = DB_ID(  'RandomActsOfSQL') 
							OR DU.database_id = DB_ID('WideWorldImporters'))
                        AND I.type_desc = 'nonclustered'
                        AND I.is_primary_key = 0
                        AND I.is_unique_constraint = 0
        ORDER BY        (DU.user_seeks + DU.user_scans + DU.user_lookups) ASC;
END;
