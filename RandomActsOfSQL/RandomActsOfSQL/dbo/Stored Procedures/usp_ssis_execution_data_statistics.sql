
-- ================================================
-- Author:		Elaena Bakman		 
-- Create date: 03/08/2018
-- Description:	This stored procedure will return 
-- the row counts from the dataflow task as the data
-- flows from one component to the next.
-- Update:		
-- ================================================

CREATE PROCEDURE dbo.usp_ssis_execution_data_statistics (
        @ExecutionId BIGINT)
AS
BEGIN
        SET NOCOUNT ON;

        SELECT      EDS.execution_id AS ExecutionID
                   ,EDS.package_name AS PackageName
				   ,EDS.task_name AS TaskName
                   ,EDS.source_component_name AS SourceComponentName
                   ,EDS.dataflow_path_name AS DataFlowPathName
                   ,EDS.destination_component_name AS DestinationComponentName
                   ,SUM(    EDS.rows_sent) AS RowsSentFromSourceToDestinationComponent
                   ,MAX(    EDS.created_time) AS ComponentExecutionTime
        FROM        SSISDB.catalog.execution_data_statistics EDS
        WHERE       EDS.execution_id = @ExecutionId
        GROUP BY    EDS.execution_id
                   ,EDS.package_name
				   ,EDS.task_name
                   ,EDS.source_component_name
                   ,EDS.dataflow_path_name
                   ,EDS.destination_component_name
        ORDER BY    ComponentExecutionTime;
END;
