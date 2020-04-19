

-- ================================================
-- Author:		Elaena Bakman		 
-- Create date: 01/02/2019
-- Description:	This stored procedure will show you
-- the parameters that were used at run time.
-- Update:		
-- ================================================
CREATE PROCEDURE dbo.usp_ssis_run_time_parameters
(@ExecutionId BIGINT)
AS
BEGIN
        SET NOCOUNT ON;

        SELECT          E.folder_name
                       ,E.project_name
                       ,E.package_name
                       ,EPV.object_type
                       ,OTN.object_type_name
                       ,EPV.parameter_data_type
                       ,EPV.parameter_name
                       ,EPV.parameter_value
                       ,EPV.sensitive
                       ,EPV.required
                       ,EPV.value_set
                       ,EPV.runtime_override
        FROM            SSISDB.catalog.execution_parameter_values EPV
        INNER   JOIN    SSISDB.catalog.executions E
        ON E.execution_id = EPV.execution_id
        CROSS   APPLY
                        (SELECT         IQ.object_type
                                       ,IQ.object_type_name
                         FROM
                                        (VALUES
                                                 (20, 'Project')
                                                ,(30, 'Package')) IQ (object_type, object_type_name)
                         WHERE          IQ.object_type = EPV.object_type) OTN
        WHERE           E.package_name = 'Load CLG Loan.dtsx'
                        AND     E.execution_id = @ExecutionId
                        AND     EPV.object_type != 50
                        AND     EPV.value_set = 1;
END;
