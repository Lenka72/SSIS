
-- ================================================
-- Author:		Elaena Bakman	 
-- Create date: 12/19/2017
-- Description:	This stored procedure will be used
--  to set the Environment Variable to be used for
-- the Trendix Process to run it based on the 
-- population type, but it is generic and can be 
-- used any time we need to pass a value into an
-- SSIS package. 
-- Update:		
-- ================================================

CREATE PROCEDURE dbo.usp_set_environment_parameter_value (
        @FolderName NVARCHAR(128)
       ,@EnvironmentName NVARCHAR(128)
       ,@EnvironmentVariableName NVARCHAR(128)
       ,@ParameterValue SQL_VARIANT)
AS
BEGIN
        SET NOCOUNT ON;

        EXEC SSISDB.catalog.set_environment_variable_value @folder_name = @FolderName
                                                          ,@environment_name = @EnvironmentName
                                                          ,@variable_name = @EnvironmentVariableName
                                                          ,@value = @ParameterValue;
END;
